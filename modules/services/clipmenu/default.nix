{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.services.clipmenu;
in
{
  meta.maintainers = [ lib.maintainers.DamienCassou ];

  options.services.clipmenu = {
    enable = lib.mkEnableOption "clipmenu, the clipboard management daemon";

    package = mkOption {
      type = types.package;
      default = pkgs.clipmenu;
      defaultText = "pkgs.clipmenu";
      description = "clipmenu derivation to use.";
    };

    launcher = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "rofi";
      description = ''
        Launcher command, if not set, {command}`dmenu`
        will be used by default.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.clipmenu" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    home.sessionVariables = lib.mkIf (cfg.launcher != null) { CM_LAUNCHER = cfg.launcher; };

    systemd.user.services.clipmenu = {
      Unit = {
        Description = "Clipboard management daemon";
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/clipmenud";
        Environment = [
          "PATH=${
            lib.makeBinPath (
              with pkgs;
              [
                coreutils
                findutils
                gnugrep
                gnused
                systemd
              ]
            )
          }"
        ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
