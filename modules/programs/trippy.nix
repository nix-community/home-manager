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

  cfg = config.programs.trippy;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.trippy = {
    enable = mkEnableOption "trippy";
    package = mkPackageOption pkgs "trippy" { nullable = true; };
    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = {
        theme-colors = {
          bg-color = "black";
          border-color = "gray";
          text-color = "gray";
          tab-text-color = "green";
        };
        bindings = {
          toggle-help = "h";
          toggle-help-alt = "?";
          toggle-settings = "s";
          toggle-settings-tui = "1";
          toggle-settings-trace = "2";
          toggle-settings-dns = "3";
          toggle-settings-geoip = "4";
        };
      };
      description = ''
        Configuration settings for trippy. All the available options can be found
        here: <https://trippy.rs/reference/configuration/>
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."trippy/trippy.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "trippy-config" cfg.settings;
    };
  };
}
