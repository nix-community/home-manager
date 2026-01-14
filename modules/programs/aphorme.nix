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

  cfg = config.programs.aphorme;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.aphorme = {
    enable = mkEnableOption "aphorme";
    package = mkPackageOption pkgs "aphorme" { nullable = true; };
    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        gui_cfg = {
          icon = true;
          ui_framework = "EGUI";
          font_size = 12;
          window_size = [
            300
            300
          ];
        };

        app_cfg = {
          paths = [ "$HOME/Desktop" ];
        };
      };
      description = ''
        Configuration settings for aphorme. All the available options can be found here:
        <https://github.com/Iaphetes/aphorme_launcher?tab=readme-ov-file#configuration>
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.aphorme" pkgs lib.platforms.linux)
    ];
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    home.file.".config/aphorme/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "aphorme-config.toml" cfg.settings;
    };
  };
}
