{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.obs-studio;
  package = pkgs.obs-studio;

  mkPluginEnv = packages: let
    pluginDirs = builtins.map
      (pkg: "${pkg}/share/obs/obs-plugins") packages;
  in pkgs.runCommand "obs-studio-plugins" {} ''
    mkdir $out
    for plugin in ${builtins.concatStringsSep " "
      (builtins.map (p: "${p}/*") pluginDirs)}; do
      ln -s "$plugin" $out/
    done
  '';

in

{
  meta.maintainers = [ maintainers.adisbladis ];

  options = {
    programs.obs-studio = {

      enable = mkOption {
        default = false;
        example = true;
        description = "Whether to enable obs-studio.";
        type = types.bool;
      };

      plugins = mkOption {
        default = [];
        example = literalExample "[ pkgs.obs-linuxbrowser ]";
        description = "Optional OBS plugins.";
        type = types.listOf types.package;
      };

    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ package ];
    }

    (mkIf (cfg.plugins != []) {
      xdg.configFile."obs-studio/plugins".source = mkPluginEnv cfg.plugins;
    })

  ]);
}
