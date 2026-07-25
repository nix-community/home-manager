{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "flake-edit";
  cfg = config.programs.${name};
  tomlFormat = pkgs.formats.toml { };
  configFile = "config.toml";
  configPath = "${name}/${configFile}";
in
{
  meta.maintainers = with lib.maintainers; [ malix ];

  options.programs.${name} = {
    enable = lib.mkEnableOption name;

    package = lib.mkPackageOption pkgs name { nullable = true; };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        follow = {
          ignore = [
            "systems"
            "crane.flake-utils"
          ];
          transitive_min = 2;
          aliases = {
            nixpkgs = [ "nixpkgs-lib" ];
          };
          max_depth = 1;
        };
      };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/${configPath}`.
        See <https://github.com/a-kenji/${name}#configuration> for documentation.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile.${configPath} = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate configFile cfg.settings;
    };
  };
}
