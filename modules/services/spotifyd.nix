{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) literalExpression;

  cfg = config.services.spotifyd;

  tomlFormat = pkgs.formats.toml { };

  configFile = tomlFormat.generate "spotifyd.conf" cfg.settings;

in
{
  options.services.spotifyd = {
    enable = lib.mkEnableOption "SpotifyD connect";

    package = lib.mkPackageOption pkgs "spotifyd" {
      example = "(pkgs.spotifyd.override { withKeyring = true; })";
      extraDescription = ''
        Can be used to specify extensions.
      '';
    };

    settings = lib.mkOption {
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

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.spotifyd" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.spotifyd = {
      Unit = {
        Description = "spotify daemon";
        Documentation = "https://github.com/Spotifyd/spotifyd";
      };

      Install.WantedBy = [ "default.target" ];

      Service = {
        ExecStart = "${cfg.package}/bin/spotifyd --no-daemon --config-path ${configFile}";
        Restart = "always";
        RestartSec = 12;
      };
    };
  };
}
