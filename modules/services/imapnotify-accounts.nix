{ pkgs, lib, ... }:
let inherit (lib) mkOption types;
in {
  options.imapnotify = {
    enable = lib.mkEnableOption "imapnotify";

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

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "-wait 1" ];
      description = "Extra arguments to pass to goimapnotify.";
    };

    extraConfig = mkOption {
      type = let jsonFormat = pkgs.formats.json { }; in jsonFormat.type;
      default = { };
      description = "Additional configuration to add for this account.";
    };
  };
}
