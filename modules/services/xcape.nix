{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.xcape;

in {
  meta.maintainers = [ maintainers.nickhu ];

  options = {
    services.xcape = {
      enable = mkEnableOption "xcape";

      timeout = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 500;
        description = ''
          If you hold a key longer than this timeout, xcape will not
          generate a key event. Default is 500 ms.
        '';
      };

      mapExpression = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = {
          Shift_L = "Escape";
          Control_L = "Control_L|O";
        };
        description = ''
          The value has the grammar `Key[|OtherKey]`.

          The list of key names is found in the header file
          {file}`X11/keysymdef.h` (remove the
          `XK_` prefix). Note that due to limitations
          of X11 shifted keys must be specified as a shift key
          followed by the key to be pressed rather than the actual
          name of the character. For example to generate "{" the
          expression `Shift_L|bracketleft` could be
          used (assuming that you have a key with "{" above "[").

          You can also specify keys in decimal (prefix #), octal (#0),
          or hexadecimal (#0x). They will be interpreted as keycodes
          unless no corresponding key name is found.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.xcape" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.xcape = {
      Unit = mkMerge [
        {
          Description = "xcape";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        }
        (mkIf (config.home.keyboard != null && config.home.keyboard != { }) {
          After = [ "graphical-session-pre.target" "setxkbmap.service" ];
        })
      ];

      Service = {
        Type = "forking";
        ExecStart = "${pkgs.xcape}/bin/xcape"
          + optionalString (cfg.timeout != null) " -t ${toString cfg.timeout}"
          + optionalString (cfg.mapExpression != { }) " -e '${
             builtins.concatStringsSep ";"
             (attrsets.mapAttrsToList (n: v: "${n}=${v}") cfg.mapExpression)
           }'";
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
