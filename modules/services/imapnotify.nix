{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.imapnotify;

  safeName = lib.replaceStrings [ "@" ":" "\\" "[" "]" ] [ "-" "-" "-" "" "" ];

  configName = account: "imapnotify-${safeName account.name}-config.json";

  imapnotifyAccounts =
    filter (a: a.imapnotify.enable) (attrValues config.accounts.email.accounts);

  genAccountUnit = account:
    let name = safeName account.name;
    in {
      name = "imapnotify-${name}";
      value = {
        Unit = { Description = "imapnotify for ${name}"; };

        Service = {
          # Use the nix store path for config to ensure service restarts when it changes
          ExecStart =
            "${getExe cfg.package} -conf '${genAccountConfig account}'";
          Restart = "always";
          RestartSec = 30;
          Type = "simple";
        } // optionalAttrs account.notmuch.enable {
          Environment =
            "NOTMUCH_CONFIG=${config.xdg.configHome}/notmuch/default/config";
        };

        Install = { WantedBy = [ "default.target" ]; };
      };
    };

  genAccountAgent = account:
    let name = safeName account.name;
    in {
      name = "imapnotify-${name}";
      value = {
        enable = true;
        config = {
          # Use the nix store path for config to ensure service restarts when it changes
          ProgramArguments =
            [ "${getExe cfg.package}" "-conf" "${genAccountConfig account}" ];
          KeepAlive = true;
          ThrottleInterval = 30;
          ExitTimeOut = 0;
          ProcessType = "Background";
          RunAtLoad = true;
        } // optionalAttrs account.notmuch.enable {
          EnvironmentVariables.NOTMUCH_CONFIG =
            "${config.xdg.configHome}/notmuch/default/config";
        };
      };
    };

  genAccountConfig = account:
    pkgs.writeText (configName account) (let
      port = if account.imap.port != null then
        account.imap.port
      else if account.imap.tls.enable then
        993
      else
        143;

      toJSON = builtins.toJSON;
    in toJSON ({
      inherit (account.imap) host;
      inherit port;
      tls = account.imap.tls.enable;
      username = account.userName;
      passwordCmd =
        lib.concatMapStringsSep " " lib.escapeShellArg account.passwordCommand;
      inherit (account.imapnotify) boxes;
    } // optionalAttrs (account.imapnotify.onNotify != "") {
      onNewMail = account.imapnotify.onNotify;
    } // optionalAttrs (account.imapnotify.onNotifyPost != "") {
      onNewMailPost = account.imapnotify.onNotifyPost;
    } // account.imapnotify.extraConfig));

in {
  meta.maintainers = [ maintainers.nickhu ];

  options = {
    services.imapnotify = {
      enable = mkEnableOption "imapnotify";

      package = mkOption {
        type = types.package;
        default = pkgs.goimapnotify;
        defaultText = literalExpression "pkgs.goimapnotify";
        example = literalExpression "pkgs.imapnotify";
        description = "The imapnotify package to use";
      };
    };

    accounts.email.accounts = mkOption {
      type = with types; attrsOf (submodule (import ./imapnotify-accounts.nix));
    };
  };

  config = mkIf cfg.enable {
    assertions = let
      checkAccounts = pred: msg:
        let badAccounts = filter pred imapnotifyAccounts;
        in {
          assertion = badAccounts == [ ];
          message = "imapnotify: Missing ${msg} for accounts: "
            + concatMapStringsSep ", " (a: a.name) badAccounts;
        };
    in [
      (checkAccounts (a: a.maildir == null) "maildir configuration")
      (checkAccounts (a: a.imap == null) "IMAP configuration")
      (checkAccounts (a: a.passwordCommand == null) "password command")
      (checkAccounts (a: a.userName == null) "username")
    ];

    systemd.user.services = listToAttrs (map genAccountUnit imapnotifyAccounts);

    launchd.agents = listToAttrs (map genAccountAgent imapnotifyAccounts);

    xdg.configFile = listToAttrs (map (account: {
      name = "imapnotify/${configName account}";
      value.source = genAccountConfig account;
    }) imapnotifyAccounts);
  };
}
