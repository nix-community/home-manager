{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.avizo;
  settingsFormat = pkgs.formats.ini { };
in
{
  meta.maintainers = [ lib.hm.maintainers.pltanton ];

  options.services.avizo = {
    enable = lib.mkEnableOption "avizo, a simple notification daemon";

    settings = lib.mkOption {
      type = (pkgs.formats.ini { }).type;
      default = { };
      example = lib.literalExpression ''
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

    package = lib.mkPackageOption pkgs "avizo" {
      example = ''
        pkgs.avizo.overrideAttrs (final: prev: {
          patchPhase = "cp ''${./images}/*.png data/images/";
        })
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.avizo" pkgs lib.platforms.linux)
    ];

    xdg.configFile."avizo/config.ini" = lib.mkIf (cfg.settings != { }) {
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

        Install = {
          WantedBy = [ config.wayland.systemd.target ];
        };
      };
    };
  };
}
