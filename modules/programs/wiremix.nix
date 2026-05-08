{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.wiremix;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.maintainers.rachitvrma ];

  options.programs.wiremix = {
    enable = lib.mkEnableOption "wiremix";

    package = lib.mkPackageOption pkgs "wiremix" { nullable = true; };

    settings = {
      inherit (tomlFormat) type;

      default = { };

      example = lib.literalExpression ''
        {
          mouse = false;
          peaks = "auto";
          theme = "default";
          max_volume_percent = 100.0;
        }
      '';

      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/wiremix/wiremix.toml`

        See <https://github.com/tsowell/wiremix#configuration> for more
        information.
      '';
    };

  };
  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."wiremix/wiremix.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "wiremix.toml" cfg.settings;
    };
  };
}
