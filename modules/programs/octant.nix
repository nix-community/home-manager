{ config, lib, pkgs, ... }:
let
  inherit (lib) literalExpression;

  cfg = config.programs.octant;

  mkPluginEnv = packages:
    let
      pluginDirs = map (pkg: "${pkg}/bin") packages;
      plugins = lib.concatMapStringsSep " " (p: "${p}/*") pluginDirs;
    in pkgs.runCommandLocal "octant-plugins" { } ''
      mkdir $out
      [[ '${plugins}' ]] || exit 0
      for plugin in ${plugins}; do
        ln -s "$plugin" $out/
      done
    '';

in {
  meta.maintainers = with lib.maintainers; [ jk ];

  options = {
    programs.octant = {
      enable = lib.mkEnableOption "octant";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.octant;
        defaultText = literalExpression "pkgs.octant";
        example = literalExpression "pkgs.octant-other";
        description = "The Octant package to use.";
      };

      plugins = lib.mkOption {
        default = [ ];
        example = literalExpression "[ pkgs.starboard-octant-plugin ]";
        description = "Optional Octant plugins.";
        type = lib.types.listOf lib.types.package;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."octant/plugins" =
      lib.mkIf (cfg.plugins != [ ]) { source = mkPluginEnv cfg.plugins; };
  };
}
