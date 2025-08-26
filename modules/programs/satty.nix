{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.satty;

  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.hm.maintainers.gauthsvenkat ];

  options.programs.satty = {
    enable = lib.mkEnableOption "Satty - Modern Screenshot Annotation";

    package = lib.mkPackageOption pkgs "satty" { nullable = true; };

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          general = {
            fullscreen = true;
            corner-roundness = 12;
            initial-tool = "brush";
            output-filename = "/tmp/test-%Y-%m-%d_%H:%M:%S.png";
          };
          color-palette = {
            palette = [ "#00ffff" "#a52a2a" "#dc143c" "#ff1493" "#ffd700" "#008000" ];
          };
        }
      '';
      description = ''
        Configuration for Satty written to {file}`$XDG_CONFIG_HOME/satty/config.toml`.

        See the [Satty documentation](https://github.com/gabm/Satty#configuration-file)
        for available options.
      '';
    };

  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.satty" pkgs lib.platforms.linux)
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."satty/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "satty-config.toml" cfg.settings;
    };
  };
}
