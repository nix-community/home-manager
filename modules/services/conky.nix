{ config, lib, pkgs, ... }:

let cfg = config.services.conky;

in with lib; {

  meta.maintainers = [ maintainers.kaleo ];

  options = {
    services.conky = {
      enable = mkEnableOption "conky, a light-weight system monitor";

      package = mkPackageOption pkgs "conky" { };

      settings = lib.mkOption {
        type = types.lines;
        default = "";
        description = ''
          Configuration written to {file}`$XDG_CONFIG_HOME/conky/conky.conf`.
          Check <https://github.com/brndnmtthws/conky/wiki/Configurations"> for options.
          If not set, the default configuration, as described by {command}`conky --print-config`, will be used.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    assertions =
      [ (hm.assertions.assertPlatform "services.conky" pkgs platforms.linux) ];

    home.packages = [ cfg.package ];

    xdg.configFile =
      mkIf (cfg.settings != "") { "conky/conky.conf".text = cfg.settings; };

    systemd.user.services.conky = {
      Unit = {
        Description = "Conky - Lightweight system monitor";
        After = [ "graphical-session.target" ];
      };

      Service = {
        Restart = "always";
        RestartSec = "3";
        ExecStart = toString ([ "${pkgs.conky}/bin/conky" ]
          ++ optional (cfg.settings != "")
          "--config ${config.xdg.configHome}/conky/conky.conf");
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}

