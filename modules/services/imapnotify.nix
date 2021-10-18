{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.imapnotify;

  safeName = lib.replaceChars [ "@" ":" "\\" "[" "]" ] [ "-" "-" "-" "" "" ];

  imapnotifyAccounts =
    filter (a: a.imapnotify.enable) (attrValues config.accounts.email.accounts);

  genAccountUnit = account:
    let name = safeName account.name;
    in {
      name = "imapnotify-${name}";
      value = {
        Unit = { Description = "imapnotify for ${name}"; };

        Service = {
          ExecStart = "${pkgs.goimapnotify}/bin/goimapnotify -conf ${
              genAccountConfig account
            }";
          Restart = "always";
          RestartSec = 30;
          Type = "simple";
        } // optionalAttrs account.notmuch.enable {
          Environment =
            "NOTMUCH_CONFIG=${config.xdg.configHome}/notmuch/notmuchrc";
        };

        Install = { WantedBy = [ "default.target" ]; };
      };
    };

  genAccountConfig = account:
    pkgs.writeText "imapnotify-${safeName account.name}-config.json" (let
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
    services.imapnotify = { enable = mkEnableOption "imapnotify"; };

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
      (lib.hm.assertions.assertPlatform "services.imapnotify" pkgs
        lib.platforms.linux)
      (checkAccounts (a: a.maildir == null) "maildir configuration")
      (checkAccounts (a: a.imap == null) "IMAP configuration")
      (checkAccounts (a: a.passwordCommand == null) "password command")
      (checkAccounts (a: a.userName == null) "username")
    ];

    systemd.user.services = listToAttrs (map genAccountUnit imapnotifyAccounts);
  };
}
