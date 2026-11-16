{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.hyfetch;

  jsonFormat = pkgs.formats.json { };

  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else config.xdg.configHome;
in
{
  meta.maintainers = [ lib.hm.maintainers.lilyinstarlight ];

  options.programs.hyfetch = {
    enable = lib.mkEnableOption "hyfetch";

    package = lib.mkPackageOption pkgs "hyfetch" { };

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        preset = "rainbow";
        mode = "rgb";
        color_align = {
          mode = "horizontal";
        };
      };
      description = ''
        JSON configuration for HyFetch.

        Configuration written to
        {file}`$XDG_CONFIG_HOME/hyfetch.json` on Linux or
        {file}`~/Library/Application Support/hyfetch.json` on Darwin.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file."${configDir}/hyfetch.json" = {
      enable = cfg.settings != { };
      source = jsonFormat.generate "hyfetch.json" cfg.settings;
    };
  };
}
