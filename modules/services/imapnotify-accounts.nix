{ lib, ... }:

with lib;

{
  options.imapnotify = {
    enable = mkEnableOption "imapnotify";

    onNotify = mkOption {
      type = with types; either str (attrsOf str);
      default = "";
      example = "\${pkgs.isync}/bin/mbsync test-%s";
      description = "Shell commands to run on any event.";
    };

    onNotifyPost = mkOption {
      type = with types; either str (attrsOf str);
      default = "";
      example = {
        mail =
          "\${pkgs.notmuch}/bin/notmuch new && \${pkgs.libnotify}/bin/notify-send 'New mail arrived'";
      };
      description = "Shell commands to run after onNotify event.";
    };

    boxes = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "Inbox" "[Gmail]/MyLabel" ];
      description = "IMAP folders to watch.";
    };

    extraConfig = mkOption {
      type = with types; attrsOf (oneOf [ bool int str ]);
      default = { };
      example = { wait = 10; };
      description = "Additional configuration to add for this account.";
    };
  };
}
