{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.octant;

  mkPluginEnv = packages:
    let
      pluginDirs = map (pkg: "${pkg}/bin") packages;
      plugins = concatMapStringsSep " " (p: "${p}/*") pluginDirs;
    in pkgs.runCommandLocal "octant-plugins" { } ''
      mkdir $out
      [[ '${plugins}' ]] || exit 0
      for plugin in ${plugins}; do
        ln -s "$plugin" $out/
      done
    '';

in {
  meta.maintainers = with maintainers; [ jk ];

  options = {
    programs.octant = {
      enable = mkEnableOption "octant";

      package = mkOption {
        type = types.package;
        default = pkgs.octant;
        defaultText = literalExpression "pkgs.octant";
        example = literalExpression "pkgs.octant-other";
        description = "The Octant package to use.";
      };

      plugins = mkOption {
        default = [ ];
        example = literalExpression "[ pkgs.starboard-octant-plugin ]";
        description = "Optional Octant plugins.";
        type = types.listOf types.package;
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."octant/plugins" =
      mkIf (cfg.plugins != [ ]) { source = mkPluginEnv cfg.plugins; };
  };
}
