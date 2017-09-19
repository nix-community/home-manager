{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.vim;
  defaultPlugins = [ "sensible" ];

in

{
  options = {
    programs.vim = {
      enable = mkEnableOption "Vim";

      lineNumbers = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether to show line numbers.";
      };
      expandTab = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = "Whether to convert tabs into spaces.";
      };
      tabSize = mkOption {
        type = types.nullOr types.int;
        default = null; 
        example = 4;
        description = "Set tab size and shift width to a specified number of spaces.";
      };

      plugins = mkOption {
        type = types.listOf types.str;
        default = defaultPlugins;
        example = [ "YankRing" ];
        description = ''
          List of vim plugins to install.
          For supported plugins see: https://github.com/NixOS/nixpkgs/blob/master/pkgs/misc/vim-plugins/vim-plugin-names
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          set nocompatible
          set nobackup
        '';
        description = "Custom .vimrc lines";
      };

      package = mkOption {
        type = types.package;
        description = "Resulting customized vim package";
        readOnly = true;
      };
    };
  };

  config = (
    let
      optionalBoolean = name: val: optionalString (val != null) (if val then "set ${name}" else "set no${name}");
      optionalInteger = name: val: optionalString (val != null) "set ${name}=${toString val}";
      customRC = ''
        ${optionalBoolean "number" cfg.lineNumbers}
        ${optionalBoolean "expandtab" cfg.expandTab}
        ${optionalInteger "tabstop" cfg.tabSize}
        ${optionalInteger "shiftwidth" cfg.tabSize}

        ${cfg.extraConfig}
      '';

      vim = pkgs.vim_configurable.customize {
        name = "vim";
        vimrcConfig.customRC = customRC;
        vimrcConfig.vam.knownPlugins = pkgs.vimPlugins;
        vimrcConfig.vam.pluginDictionaries = [
          { names = defaultPlugins ++ cfg.plugins; }
        ];
      };

    in mkIf cfg.enable {
      programs.vim.package = vim;
      home.packages = [ cfg.package ];
    }
  );
}
