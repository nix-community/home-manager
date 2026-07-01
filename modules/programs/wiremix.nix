{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    hm
    mkIf
    mkEnableOption
    mkOption
    mkPackageOption
    platforms
    ;

  cfg = config.programs.wiremix;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.maintainers.rachitvrma ];

  options.programs.wiremix = {
    enable = mkEnableOption "wiremix";

    package = mkPackageOption pkgs "wiremix" { nullable = true; };

    settings = mkOption {
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
  config = mkIf cfg.enable {

    assertions = [
      (hm.assertions.assertPlatform "programs.wiremix" pkgs platforms.linux)
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."wiremix/wiremix.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "wiremix.toml" cfg.settings;
    };
  };
}
