{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zsh.zplug;

  pluginModule = types.submodule ({ config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        description = "The name of the plugin.";
      };

      tags = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "The plugin tags.";
      };
    };

  });

in {
  options.programs.zsh.zplug = {
    enable = mkEnableOption "zplug - a zsh plugin manager";

    package = mkOption {
      type = types.package;
      default = pkgs.zplug;
      defaultText = literalExpression "pkgs.zplug";
      description = "The zplug package to install.";
    };

    zplugPackageRootDir = mkOption {
      type = with types; either str path;
      default = "${cfg.package}";
      defaultText = literalExpression "cfg.package";
      description =
        "Path to the dir that contains the outputs (e.g. init.zsh) of the zplug package.";
    };

    plugins = mkOption {
      default = [ ];
      type = types.listOf pluginModule;
      description = "List of zplug plugins.";
    };

    zplugHome = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/.zplug";
      defaultText = "~/.zplug";
      apply = toString;
      description = "Path to zplug home directory.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.zplug ];

    programs.zsh.initExtraBeforeCompInit = ''
      export ZPLUG_HOME=${cfg.zplugHome}

      source ${cfg.zplugPackageRootDir}/init.zsh

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
