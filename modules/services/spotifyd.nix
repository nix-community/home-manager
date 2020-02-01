{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.spotifyd;

  configFile = pkgs.writeText "spotifyd.conf" ''
    ${generators.toINI { } cfg.settings}
  '';

in {
  options.services.spotifyd = {
    enable = mkEnableOption "SpotifyD connect";

    settings = mkOption {
      type = types.attrsOf (types.attrsOf types.str);
      default = { };
      description = "Configuration for spotifyd";
      example = literalExample ''
        {
          global = {
            user = "Alex";
            password = "foo";
            device_name = "nix";
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.spotifyd ];

    systemd.user.services.spotifyd = {
      Unit = {
        Description = "spotify daemon";
        Documentation = "https://github.com/Spotifyd/spotifyd";
      };

      Install.WantedBy = [ "default.target" ];

      Service = {
        ExecStart =
          "${pkgs.spotifyd}/bin/spotifyd --no-daemon --config-path ${configFile}";
        Restart = "always";
        RestartSec = 12;
      };
    };
  };
}
