{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.obs-studio;

  mkPluginEnv = packages:
    let
      pluginDirs = map (pkg: "${pkg}/share/obs/obs-plugins") packages;
      plugins = concatMapStringsSep " " (p: "${p}/*") pluginDirs;
    in pkgs.runCommand "obs-studio-plugins" {
      preferLocalBuild = true;
      allowSubstitutes = false;
    } ''
      mkdir $out
      [[ '${plugins}' ]] || exit 0
      for plugin in ${plugins}; do
        ln -s "$plugin" $out/
      done
    '';

in {
  meta.maintainers = [ maintainers.adisbladis ];

  options = {
    programs.obs-studio = {
      enable = mkEnableOption "obs-studio";

      package = mkOption {
        type = types.package;
        default = pkgs.obs-studio;
        defaultText = literalExample "pkgs.obs-studio";
        description = ''
          OBS Studio package to install.
        '';
      };

      plugins = mkOption {
        default = [ ];
        example = literalExample "[ pkgs.obs-linuxbrowser ]";
        description = "Optional OBS plugins.";
        type = types.listOf types.package;
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."obs-studio/plugins" =
      mkIf (cfg.plugins != [ ]) { source = mkPluginEnv cfg.plugins; };
  };
}
