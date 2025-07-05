{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    mkEnableOption
    mkPackageOption
    ;

  cfg = config.programs.arduino-cli;

  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.arduino-cli = {
    enable = mkEnableOption "arduino-cli";
    package = mkPackageOption pkgs "arduino-cli" { nullable = true; };
    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      example = { };
      description = ''
        Configuration settings for arduino-cli. All the available options
        can be found here: <https://docs.arduino.cc/arduino-cli/configuration/>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    home.file.".arduino15/arduino-cli.yaml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "arduino-cli-config" cfg.settings;
    };
  };
}
