{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.aerc;

  aercAccounts =
    filter (a: a.aerc.enable) (attrValues config.accounts.email.accounts);

  bindContextsModule = types.submodule {
    globalBinds = mkOption {
      type = types.listOf bindModule;
      default = [ ];
      description = "List of global keybindings.";
    };
    messages = mkOption {
      type = types.nullOr contextModule;
      default = null;
      description = "Keybindings for the message list.";
    };
    view = mkOption {
      type = types.nullOr contextModule;
      default = null;
      description = "Keybindings for the message viewer.";
    };
    compose = mkOption {
      type = types.nullOr contextModule;
      default = null;
      description = "Keybindings for the message composer.";
    };
    "compose::editor" = mkOption {
      type = types.nullOr contextModule;
      default = null;
      description = "Keybindings for the composer, when the editor is focused.";
    };
    "compose::review" = mkOption {
      type = types.nullOr contextModule;
      default = null;
      description =
        "Keybindings for the composer, when reviewing the email before it's sent.";
    };
    terminal = mkOption {
      type = types.nullOr contextModule;
      default = null;
      description = "Keybindings for terminal tabs.";
    };
  };

  contextModule = types.submodule {
    noinherit = mkOption {
      type = types.bool;
      default = false;
      description = "Disable global keybindings in this context.";
    };

    ex = mkOption {
      type = types.str;
      default = "<semicolon>";
      description = "The keystroke that will bring up the command input.";
    };

    binds = mkOption {
      type = types.listOf bindModule;
      default = [ ];
      description = "List of keybindings.";
    };
  };

  bindModule = types.submodule {
    options = {
      keystrokes = mkOption {
        type = types.str;
        example = "rq";
        description =
          "The keystrokes pressed (in order) to invoke this keybinding.";
      };

      action = mkOption {
        type = types.str;
        example = ":reply -q<Enter>";
        description =
          "The keystrokes simulated when the keybinding is invoked.";
      };
    };
  };

  imapSource = a:
    assert a.imap != null;
    assert a.passwordCommand != null;
    with a.imap;
    let
      imapSecurity =
        if tls.enable then if tls.useStartTls then "" else "s" else "+insecure";
      imapPort = if port != null then ":${toString port}" else "";
    in ''
      source = imap${imapSecurity}://${a.userName}@${host}${imapPort}
      source-cred-cmd = ${a.passwordCommand}
    '';

  maildirSource = a:
    assert a.maildir != null;
    let
      proto = if a.notmuch.enable then "notmuch" else "maildir";
      basePath = config.accounts.email.maildirBasePath;
    in "source = ${proto}://${basePath}/${a.maildir.path}";

  outgoing = a:
    if a.aerc.sendMailCommand == null then
      assert a.smtp != null;
      with a.smtp;
      let
        smtpSecurity = if !tls.enable || tls.useStartTls then "" else "s";
        smtpPort = if port != null then ":${toString port}" else "";
      in ''
        outgoing = smtp${smtpSecurity}://${a.userName}@${host}${smtpPort}
        outgoing-cred-cmd = ${a.passwordCommand}
        ${optionalString (tls.enable && tls.useStartTls) "smtp-starttls = yes"}
      ''
    else "outgoing = ${a.aerc.sendMailCommand}";

  signature = a: pkgs.writeText "signature.txt" a.signature.text;

  accountSection = a: ''
    [${a.name}]
    from = "${a.realName} <${a.address}>"
    postpone = ${a.folders.drafts}
    default = ${a.folders.inbox}
    ${outgoing a}
    ${(if a.aerc.source == "imap" then imapSource else maildirSource) a}
    ${optionalString (a.signature.text != "") "signature-file = ${signature a}"}
    ${optionalString (a.flavor != "gmail.com") "copy-to = ${a.folders.sent}"}
    ${optionalString (a.aerc.settings != { }) (generators.toINI { } a.aerc.settings)}
  '';

  genBinds = concatMapStringsSep "\n" (b: "${b.keystrokes} = ${b.action}");

  genBindContextSection = name: ctx: ''
    [${name}]
    ${genBinds ctx.binds}
    $noinherit = ${ctx.noinherit}
    $ex = ${ctx.ex}
  '';

  bindsConf = optionalString (cfg.bindContexts == null) ''
  '';

in {
  options = {
    programs.aerc = {
      enable = mkEnableOption "the Aerc mail client";

      bindContexts = mkOption {
        type = types.nullOr bindContextsModule;
        default = null;
        description = "Keybinding contexts.";
      };

      settings = mkOption {
        type = types.attrs;
        default = { };
        description = "Extra configuration appended to the end.";
      };
    };

    accounts.email.accounts = mkOption {
      type = types.attrsOf (types.submodule (import ./aerc-accounts.nix));
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.aerc ];

    xdg.configFile."aerc/accounts.conf" = mkIf (aercAccounts != [ ]) {
      text = ''
        # Generated by Home Manager.

        ${concatMapStringsSep "\n" accountSection aercAccounts}
      '';
    };

    xdg.configFile."aerc/aerc.conf" = mkIf (aercAccounts != [ ] && cfg.settings != { }) {
      text = ''
        # Generated by Home Manager.

        ${generators.toINI { } cfg.settings}
      '';
    };

    xdg.configFile."aerc/binds.conf" = mkIf (aercAccounts != [ ] && cfg.bindContexts != null) {
      text = ''
        # Generated by Home Manager.

        ${genBinds cfg.bindContexts.globalBinds}
        ${mapAttrs genBindContextSection (removeAttrs cfg.bindContexts [ "globalBinds" ])}
      '';
    };
  };
}
