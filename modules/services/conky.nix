{ config, lib, pkgs, ... }:

let

  cfg = config.services.conky;

in with lib; {
  meta.maintainers = [ hm.maintainers.kaleo ];

  options = {
    services.conky = {
      enable = mkEnableOption "Conky, a light-weight system monitor";

      package = mkPackageOption pkgs "conky" { };

      extraConfig = lib.mkOption {
        type = types.lines;
        default = "";
        description = ''
          Configuration used by the Conky daemon. Check
          <https://github.com/brndnmtthws/conky/wiki/Configurations> for
          options. If not set, the default configuration, as described by
          {command}`conky --print-config`, will be used.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions =
      [ (hm.assertions.assertPlatform "services.conky" pkgs platforms.linux) ];

    home.packages = [ cfg.package ];

    systemd.user.services.conky = {
      Unit = {
        Description = "Conky - Lightweight system monitor";
        After = [ "graphical-session.target" ];
      };

      Service = {
        Restart = "always";
        RestartSec = "3";
        ExecStart = toString ([ "${pkgs.conky}/bin/conky" ]
          ++ optional (cfg.extraConfig != "")
          "--config ${pkgs.writeText "conky.conf" cfg.extraConfig}");
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}

