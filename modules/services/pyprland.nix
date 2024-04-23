{ options, config, lib, pkgs, ... }:
let
  cfg = config.services.pyprland;
  settingsFormat = pkgs.formats.toml { };
in with lib; {

  meta.maintainers = [ hm.maintainers.knoc-off ];
  options.services.pyprland = {
    enable = mkEnableOption "pyprland";

    package = mkOption {
      default = pkgs.pyprland;
      type = types.package;
      description = "The pyprland package to use";
    };

    extraPlugins = mkOption {
      default = [ ];
      type = with types; listOf str;
      description = "Additional plugins to enable";
    };

    settings = mkOption {
      type = types.submodule {
        freeformType = settingsFormat.type;

        options.scratchpads = mkOption {
          default = { };
          type = with types; attrsOf attrs;
          description = "Scratchpad configurations";
        };
      };
      default = { };
      description = ''
        Configuration for pyprland, see
        <https://github.com/hyprland-community/pyprland/wiki/Getting-started#configuring">
        for supported values.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    services.pyprland.settings = {
      pyprland = {
        plugins = cfg.extraPlugins
          ++ (optional (cfg.settings.scratchpads != { }) "scratchpads");
      };
    };

    home.file.".config/hypr/pyprland.toml".source =
      settingsFormat.generate "pyprland-config.toml" cfg.settings;
  };
}

