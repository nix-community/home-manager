{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.avizo;
  settingsFormat = pkgs.formats.ini { };
in {
  meta.maintainers = [ hm.maintainers.pltanton ];

  options.services.avizo = {
    enable = mkEnableOption "avizo, a simple notification daemon";

    settings = mkOption {
      type = (pkgs.formats.ini { }).type;
      default = { };
      example = literalExpression ''
        {
          default = {
            time = 1.0;
            y-offset = 0.5;
            fade-in = 0.1;
            fade-out = 0.2;
            padding = 10;
          };
        }
      '';
      description = ''
        The settings that will be written to the avizo configuration file.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.avizo;
      defaultText = literalExpression "pkgs.avizo";
      example = literalExpression ''
        pkgs.avizo.overrideAttrs (final: prev: {
          patchPhase = "cp ''${./images}/*.png data/images/";
        })
      '';
      description = "The `avizo` package to use.";
    };
  };

  config = mkIf cfg.enable {
    assertions =
      [ (hm.assertions.assertPlatform "services.avizo" pkgs platforms.linux) ];

    xdg.configFile."avizo/config.ini" = mkIf (cfg.settings != { }) {
      source = settingsFormat.generate "avizo-config.ini" cfg.settings;
    };

    home.packages = [ cfg.package ];

    systemd.user = {
      services.avizo = {
        Unit = {
          Description = "Volume/backlight OSD indicator";
          PartOf = [ config.wayland.systemd.target ];
          After = [ config.wayland.systemd.target ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
          Documentation = "man:avizo(1)";
        };

        Service = {
          Type = "simple";
          ExecStart = "${cfg.package}/bin/avizo-service";
          Restart = "always";
        };

        Install = { WantedBy = [ config.wayland.systemd.target ]; };
      };
    };
  };
}
