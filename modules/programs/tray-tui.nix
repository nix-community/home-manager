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

  cfg = config.programs.tray-tui;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.tray-tui = {
    enable = mkEnableOption "tray-tui";
    package = mkPackageOption pkgs "tray-tui" { nullable = true; };
    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = {
        sorting = false;
        columns = 3;
        key_map = {
          left = "focus_left";
          h = "focus_left";
          right = "focus_right";
          l = "focus_right";
          up = "focus_up";
          j = "focus_up";
          down = "focus_down";
          k = "focus_down";
        };
      };
      description = ''
        Configuration settings for tray-tui. All the available options
        can be found here: <https://github.com/Levizor/tray-tui/blob/main/config_example.toml>
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."tray-tui/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "tray-tui-config" cfg.settings;
    };
  };
}
