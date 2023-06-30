{ pkgs, lib, ... }:

with lib;

{
  options.imapnotify = {
    enable = mkEnableOption (lib.mdDoc "imapnotify");

    onNotify = mkOption {
      type = with types; either str (attrsOf str);
      default = "";
      example = "\${pkgs.isync}/bin/mbsync test-%s";
      description = lib.mdDoc "Shell commands to run on any event.";
    };

    onNotifyPost = mkOption {
      type = with types; either str (attrsOf str);
      default = "";
      example = {
        mail =
          "\${pkgs.notmuch}/bin/notmuch new && \${pkgs.libnotify}/bin/notify-send 'New mail arrived'";
      };
      description = lib.mdDoc "Shell commands to run after onNotify event.";
    };

    boxes = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "Inbox" "[Gmail]/MyLabel" ];
      description = lib.mdDoc "IMAP folders to watch.";
    };

    extraConfig = mkOption {
      type = let jsonFormat = pkgs.formats.json { }; in jsonFormat.type;
      default = { };
      example = { wait = 10; };
      description =
        lib.mdDoc "Additional configuration to add for this account.";
    };
  };
}
