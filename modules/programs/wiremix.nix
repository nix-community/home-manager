{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.wiremix;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.maintainers; [ kybe236 ];

  options.programs.wiremix = {
    enable = lib.mkEnableOption "wiremix";

    package = lib.mkPackageOption pkgs "wiremix" { nullable = true; };

    settings = lib.mkOption {
      type = lib.types.submodule { freeformType = tomlFormat.type; };
      default = { };
      example = {
        mouse = false;
        max_volume_percent = 100.0;
      };
      description = ''
        Wiremix configuration.
        See <https://github.com/tsowell/wiremix#configuration> and <https://github.com/tsowell/wiremix/blob/main/wiremix.toml> for options.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."wiremix/wiremix.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "wiremix-config.toml" cfg.settings;
    };
  };
}
