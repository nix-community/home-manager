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

  cfg = config.programs.i3bar-river;
  formatter = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.i3bar-river = {
    enable = mkEnableOption "i3bar-river";
    package = mkPackageOption pkgs "i3bar-river" { nullable = true; };
    settings = mkOption {
      type = formatter.type;
      default = { };
      example = {
        background = "#282828ff";
        color = "#ffffffff";
        separator = "#9a8a62ff";
        font = "monospace 10";
        height = 24;
        margin_top = 0;
        margin_bottom = 0;
        margin_left = 0;
        "wm.river" = {
          max_tag = 0;
        };
      };
      description = ''
        Configuration settings for i3bar-river. All available options can be
        found here: <https://github.com/MaxVerevkin/i3bar-river?tab=readme-ov-file#configuration>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."i3bar-river/config.toml" = mkIf (cfg.settings != { }) {
      source = formatter.generate "i3bar-river-config.toml" cfg.settings;
    };
  };
}
