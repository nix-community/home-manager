{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.imapnotify;

  configType = types.submodule {
    options = {
      host = mkOption {
        type = types.str;
        example = "imap.gmail.com";
        description = "IMAP server host.";
      };

      port = mkOption {
        type = types.int;
        example = "993";
        description = "IMAP server port.";
      };

      tls = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to use TLS or not.";
      };

      tlsOptions = mkOption {
        type = types.attrs;
        default = {};
        example = { rejectUnauthorized = false; };
        description = "Additional TLS options.";
      };

      username = mkOption {
        type = types.str;
        example = "<user>@gmail.com";
        description = "IMAP server username.";
      };

      password = mkOption {
        type = types.str;
        description = "IMAP server password.";
      };

      passwordCmd = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "\${pkgs.pass}/bin/pass gmail";
        description = "Shell command to get IMAP server password.";
      };

      onNotify = mkOption {
        type = types.either types.str types.attrs;
        example = "\${pkgs.mbsync}/bin/mbsync test-%s";
        description = "Shell commands to run on any event.";
      };

      onNotifyPost = mkOption {
        type = types.either types.str types.attrs;
        example = { mail = "\${pkgs.notmuch}/bin/notmuch new && \${pkgs.libnotify}/bin/notify-send 'New mail arrived'"; };
        description = "Shell commands to run after onNotify event.";
      };

      boxes = mkOption {
        type = types.listOf types.str;
        example = [ "Inbox" "[Gmail]/MyLabel" ];
        description = "IMAP folders to watch.";
      };
    };
  };

in

{
  meta.maintainers = [ maintainers.nickhu ];

  options = {
    services.imapnotify = {
      enable = mkEnableOption "imapnotify";

      settings = mkOption {
        type = configType;
        default = {};
        description = "Configuration written to ~/.config/imap_inotify/config.json";
        example = literalExample ''
          {
            host = "imap.gmail.com";
            port = 993;
            tls = true;
            tlsOptions = { rejectUnauthorized = false; };
            username = "";
            password = "";
            onNotify = "/usr/bin/mbsync test-%s";
            onNotifyPost = { mail = "''${pkgs.notmuch}/bin/notmuch new && ''${pkgs.libnotify}/bin/notify-send 'New mail arrived'"; };
            boxes = [ "Inbox" "[Gmail]/MyLabel" ];
          }
        '';
      };
    };
  };

  config = mkIf cfg.enable (
    let jsConfig = cfg.settings.passwordCmd != null;
    in mkMerge [
      {
        systemd.user.services.imapnotify = {
          Unit = {
            Description = "Execute scripts on IMAP mailbox changes (new/deleted/updated messages) using IDLE";
            PartOf = [ "network-online.target" ];
          };

          Service = {
            ExecStart = "${pkgs.imapnotify}/bin/imapnotify"
              + optionalString jsConfig " -c %E/imap_inotify/config.js";
          };
        };
      }

      (mkIf (cfg.settings != {} && !jsConfig) {
        xdg.configFile."imap_inotify/config.json".text = builtins.toJSON
          (attrsets.filterAttrs (n: v: n != "_module") cfg.settings);
      })

      (mkIf (cfg.settings != {} && jsConfig) {
        xdg.configFile."imap_inotify/config.js".text = ''
          var child_process = require('child_process');

          function getStdout(cmd) {
              var stdout = child_process.execSync(cmd);
              return stdout.toString().trim();
          }

          exports.host = "${cfg.settings.host}"
          exports.port = ${toString cfg.settings.port};
          exports.tls = ${if cfg.settings.tls then "true" else "false"};
          exports.tlsOptions = ${builtins.toJSON cfg.settings.tlsOptions};
          exports.username = "${cfg.settings.username}";
          exports.password = getStdout("${cfg.settings.passwordCmd}");
          exports.onNotify = ${builtins.toJSON cfg.settings.onNotify};
          exports.onNotifyPost = ${builtins.toJSON cfg.settings.onNotifyPost};
          exports.boxes = ${builtins.toJSON cfg.settings.boxes};
        '';
      })
    ]
  );
}
