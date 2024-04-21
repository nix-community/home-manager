{ lib, pkgs, config, ... }:

let
  inherit (lib)
    concatStringsSep mapAttrsToList mkIf mkEnableOption mkPackageOption mkOption
    literalExpression;

  cfg = config.programs.freetube;

  settings = settings:
    let
      convertSetting = name: value:
        builtins.toJSON {
          "_id" = name;
          "value" = value;
        };
    in concatStringsSep "\n" (mapAttrsToList convertSetting settings) + "\n";
in {
  meta.maintainers = with lib.maintainers; [ vonixxx ];

  options.programs.freetube = {
    enable = mkEnableOption "FreeTube, a YT client for Windows, Mac, and Linux";

    package = mkPackageOption pkgs "freetube" { };

    settings = mkOption {
      type = lib.types.attrs;
      default = { };
      example = literalExpression ''
        {
          allowDashAv1Formats = true;
          checkForUpdates     = false;
          defaultQuality      = "1080";
          baseTheme           = "catppuccinMocha";
        }
      '';
      description = ''
        Configuration settings for FreeTube.

        All configurable options can be deduced by enabling them through the
        GUI and observing the changes in {file}`settings.db`.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."FreeTube/hm_settings.db" = {
      source = pkgs.writeText "hm_settings.db" (settings cfg.settings);

      onChange = let
        hmSettingsDb = "${config.xdg.configHome}/FreeTube/hm_settings.db";
        settingsDb = "${config.xdg.configHome}/FreeTube/settings.db";
      in ''
        run install -Dm644 $VERBOSE_ARG '${hmSettingsDb}' '${settingsDb}'
      '';
    };
  };
}
