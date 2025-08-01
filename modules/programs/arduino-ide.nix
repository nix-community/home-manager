{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.arduino-ide;

  yamlFormat = pkgs.formats.yaml { };
  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.arduino-ide = {
    enable = mkEnableOption "arduino-ide";
    package = mkPackageOption pkgs "arduino-ide" { nullable = true; };
    settings = mkOption {
      type = jsonFormat.type;
      default = { };
      description = ''
        Configuration settings for Arduino IDE.
      '';
    };

    cliSettings = mkOption {
      type = yamlFormat.type;
      default = { };
      example = {
        board_manager = {
          enable_unsafe_install = true;
          additional_urls = [
            "https://downloads.arduino.cc/packages/package_staging_index.json"
          ];
        };
      };
      description = ''
        Configuration settings for the arduino-cli. All the available options
        can be found here: <https://docs.arduino.cc/arduino-cli/configuration/>.
      '';
    };

    keymaps = mkOption {
      type = jsonFormat.type;
      default = { };
      description = ''
        Keymaps declarations for Arduino IDE.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    home.file = {
      ".arduinoIDE/arduino-cli.yaml" = mkIf (cfg.cliSettings != { }) {
        source = yamlFormat.generate "arduino-ide-cli" cfg.cliSettings;
      };
      ".arduinoIDE/settings.json" = mkIf (cfg.settings != { }) {
        source = jsonFormat.generate "arduino-ide-settings" cfg.settings;
      };
      ".arduinoIDE/keymaps.json" = mkIf (cfg.keymaps != { }) {
        source = jsonFormat.generate "arduino-ide-keymaps" cfg.keymaps;
      };
    };
  };
}
