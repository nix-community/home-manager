{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.wpaperd;
  tomlFormat = pkgs.formats.toml { };
in {
  meta.maintainers = [ hm.maintainers.Avimitin ];

  options.programs.wpaperd = {
    enable = mkEnableOption "wpaperd";

    package = mkPackageOption pkgs "wpaperd" { };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          eDP-1 = {
            path = "/home/foo/Pictures/Wallpaper";
            apply-shadow = true;
          };
          DP-2 = {
            path = "/home/foo/Pictures/Anime";
            sorting = "descending";
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/wpaperd/wallpaper.toml`.
        See <https://github.com/danyspin97/wpaperd#wallpaper-configuration>
        for the full list of options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "wpaperd/wallpaper.toml" = mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "wpaperd-wallpaper" cfg.settings;
      };
    };
  };
}
