{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.spotifyd;

  tomlFormat = pkgs.formats.toml { };

  configFile = tomlFormat.generate "spotifyd.conf" cfg.settings;

in {
  options.services.spotifyd = {
    enable = mkEnableOption "SpotifyD connect";

    package = mkOption {
      type = types.package;
      default = pkgs.spotifyd;
      defaultText = literalExpression "pkgs.spotifyd";
      example =
        literalExpression "(pkgs.spotifyd.override { withKeyring = true; })";
      description = ''
        The <literal>spotifyd</literal> package to use.
        Can be used to specify extensions.
      '';
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      description = "Configuration for spotifyd";
      example = literalExpression ''
        {
          global = {
            username = "Alex";
            password = "foo";
            device_name = "nix";
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.spotifyd" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.spotifyd = {
      Unit = {
        Description = "spotify daemon";
        Documentation = "https://github.com/Spotifyd/spotifyd";
      };

      Install.WantedBy = [ "default.target" ];

      Service = {
        ExecStart =
          "${cfg.package}/bin/spotifyd --no-daemon --config-path ${configFile}";
        Restart = "always";
        RestartSec = 12;
      };
    };
  };
}
