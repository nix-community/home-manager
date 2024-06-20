{ lib, pkgs, config, ... }:

let cfg = config.services.himitsu;
in {
  options = {
    services.himitsu = {
      enable = mkEnableOption ''
        Himitsu, secret storage system for Unix systems
      '';

      package = mkPackageOption pkgs "himitsu" { };

      prompter = mkPackageOption pkgs "himitsu-prompter" {
        default = [ "hiprompt-gtk-py" ];
      };
    };
  };

  config = mkIf (cfg.enable) {
    home.packages = [ cfg.package cfg.prompter ];

    systemd.user.services.himitsu = {
      Unit = {
        Description = "Himitsu daemon";
        PartOf = "graphical-session.target";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${cfg.package}/bin/himitsud";
      };
    };

    xdg.configFile."himitsu/config.ini" = {
      text = lib.generators.toINI { } {
        himitsud = {
          prompter = lib.getExe' cfg.prompter "hiprompt-gtk";
        };
      };
    };
  };

  meta.maintainers = [ maintainers.patwid ];
}
