{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zplug;

  pkg = pkgs.srcOnly {
    name = "zplug";
    src = builtins.fetchGit {
      url = https://github.com/zplug/zplug.git;
      ref = "master";
    };
  };

  pluginModule = types.submodule ({ config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        description = ''
          The name of the plugin.
        '';
      };

      tags = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "The plugin tags";
      };
    };

  });

in {
  options.programs.zplug = {
    enable = mkEnableOption "zplug - a zsh plugin manager";


    plugins = mkOption {
        default = [];
        type = types.listOf pluginModule;
        description = ''
          List of zplug plugins
        '';
      };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkg ];

    programs.zsh.initExtraBeforeCompInit = ''
      source ${pkg}/init.zsh

      ${optionalString (cfg.plugins != []) ''
        ${concatStrings (map (plugin: ''
          zplug "${plugin.name}"${optionalString (plugin.tags != []) ''
            ${concatStrings (map (tag: ", ${tag}") plugin.tags)}
          ''} 
        '') cfg.plugins)}
      ''}

      zplug install
      zplug load
    '';

  };
}
