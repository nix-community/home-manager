{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.clipmenu;

in {
  meta.maintainers = [ maintainers.DamienCassou ];

  options.services.clipmenu = {
    enable =
      mkEnableOption (lib.mdDoc "clipmenu, the clipboard management daemon");

    package = mkOption {
      type = types.package;
      default = pkgs.clipmenu;
      defaultText = "pkgs.clipmenu";
      description = lib.mdDoc "clipmenu derivation to use.";
    };

    launcher = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "rofi";
      description = lib.mdDoc ''
        Launcher command, if not set, {command}`dmenu`
        will be used by default.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.clipmenu" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    home.sessionVariables =
      mkIf (cfg.launcher != null) { CM_LAUNCHER = cfg.launcher; };

    systemd.user.services.clipmenu = {
      Unit = {
        Description = "Clipboard management daemon";
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/clipmenud";
        Environment = "PATH=${
            makeBinPath
            (with pkgs; [ coreutils findutils gnugrep gnused systemd ])
          }";
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
