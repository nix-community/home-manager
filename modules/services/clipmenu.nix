{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.clipmenu;

in {
  meta.maintainers = [ maintainers.DamienCassou ];

  options.services.clipmenu = {
    enable = mkEnableOption "clipmenu, the clipboard management daemon";

    package = mkOption {
      type = types.package;
      default = pkgs.clipmenu;
      defaultText = "pkgs.clipmenu";
      description = "clipmenu derivation to use.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

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
