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

  cfg = config.programs.swappy;
  iniFormat = pkgs.formats.ini { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.swappy = {
    enable = mkEnableOption "swappy";
    package = mkPackageOption pkgs "swappy" { nullable = true; };
    settings = mkOption {
      inherit (iniFormat) type;
      default = { };
      example = {
        Default = {
          save_dir = "$HOME/Desktop";
          save_filename_format = "swappy-%Y%m%d-%H%M%S.png";
          show_panel = false;
          line_size = 5;
          text_size = 20;
          text_font = "sans-serif";
          paint_mode = "brush";
          early_exit = false;
          fill_shape = false;
          auto_save = false;
          custom_color = "rgba(193,125,17,1)";
          transparent = false;
          transparency = 50;
        };
      };
      description = ''
        Configuration settings for swappy. All the available options can be found
        here: <https://github.com/jtheoof/swappy?tab=readme-ov-file#config>
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.swappy" pkgs lib.platforms.linux)
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."swappy/config" = mkIf (cfg.settings != { }) {
      source = iniFormat.generate "swappy-config" cfg.settings;
    };
  };
}
