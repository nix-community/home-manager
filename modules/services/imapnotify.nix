{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.imapnotify;

  safeName = lib.replaceChars ["@" ":" "\\" "[" "]"] ["-" "-" "-" "" ""];

  imapnotifyAccounts =
    filter (a: a.imapnotify.enable)
    (attrValues config.accounts.email.accounts);

  genAccountUnit = account:
    let
      name = safeName account.name;
    in
      {
        name = "imapnotify-${name}";
        value = {
          Unit = {
            Description = "imapnotify for ${name}";
          };

          Service = {
            ExecStart = "${pkgs.imapnotify}/bin/imapnotify -c ${genAccountConfig account}";
          } // optionalAttrs account.notmuch.enable {
            Environment = "NOTMUCH_CONFIG=${config.xdg.configHome}/notmuch/notmuchrc";
          };

          Install = {
            WantedBy = [ "default.target" ];
          };
        };
      };

  genAccountConfig = account:
    pkgs.writeText "imapnotify-${safeName account.name}-config.js" (
      let
        port =
          if account.imap.port != null then account.imap.port
          else if account.imap.tls.enable then 993
          else 143;

        toJSON = builtins.toJSON;
      in
        ''
          var child_process = require('child_process');

          function getStdout(cmd) {
              var stdout = child_process.execSync(cmd);
              return stdout.toString().trim();
          }

          exports.host = ${toJSON account.imap.host}
          exports.port = ${toJSON port};
          exports.tls = ${toJSON account.imap.tls.enable};
          exports.username = ${toJSON account.userName};
          exports.password = getStdout("${toString account.passwordCommand}");
          exports.onNotify = ${toJSON account.imapnotify.onNotify};
          exports.onNotifyPost = ${toJSON account.imapnotify.onNotifyPost};
          exports.boxes = ${toJSON account.imapnotify.boxes};
        ''
    );

in

{
  meta.maintainers = [ maintainers.nickhu ];

  options = {
    services.imapnotify = {
      enable = mkEnableOption "imapnotify";
    };

    accounts.email.accounts = mkOption {
      type = with types; attrsOf (submodule (
        import ./imapnotify-accounts.nix
      ));
    };
  };

  config = mkIf cfg.enable {
    assertions =
      let
        checkAccounts = pred: msg:
          let
            badAccounts = filter pred imapnotifyAccounts;
          in
            {
              assertion = badAccounts == [];
              message = "imapnotify: Missing ${msg} for accounts: "
                + concatMapStringsSep ", " (a: a.name) badAccounts;
            };
      in
        [
          (checkAccounts (a: a.maildir == null) "maildir configuration")
          (checkAccounts (a: a.imap == null) "IMAP configuration")
          (checkAccounts (a: a.passwordCommand == null) "password command")
          (checkAccounts (a: a.userName == null) "username")
        ];

    systemd.user.services =
      listToAttrs (map genAccountUnit imapnotifyAccounts);
  };
}
