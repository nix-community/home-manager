{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zsh.zplug;

  pluginModule = types.submodule ({ config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        description = lib.mdDoc "The name of the plugin.";
      };

      tags = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = lib.mdDoc "The plugin tags.";
      };
    };

  });

in {
  options.programs.zsh.zplug = {
    enable = mkEnableOption (lib.mdDoc "zplug - a zsh plugin manager");

    plugins = mkOption {
      default = [ ];
      type = types.listOf pluginModule;
      description = lib.mdDoc "List of zplug plugins.";
    };

    zplugHome = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/.zplug";
      defaultText = "~/.zplug";
      apply = toString;
      description = lib.mdDoc "Path to zplug home directory.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.zplug ];

    programs.zsh.initExtraBeforeCompInit = ''
      export ZPLUG_HOME=${cfg.zplugHome}

      source ${pkgs.zplug}/share/zplug/init.zsh

      ${optionalString (cfg.plugins != [ ]) ''
        ${concatStrings (map (plugin: ''
          zplug "${plugin.name}"${
            optionalString (plugin.tags != [ ]) ''
              ${concatStrings (map (tag: ", ${tag}") plugin.tags)}
            ''
          }
        '') cfg.plugins)}
      ''}

      if ! zplug check; then
        zplug install
      fi

      zplug load
    '';

  };
}
