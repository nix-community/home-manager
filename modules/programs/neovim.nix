{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.neovim;

  extraPythonPackageType = mkOptionType {
    name = "extra-python-packages";
    description = "python packages in python.withPackages format";
    check = with types; (x: if isFunction x
      then isList (x pkgs.pythonPackages)
      else false);
    merge = mergeOneOption;
  };

  extraPython3PackageType = mkOptionType {
    name = "extra-python3-packages";
    description = "python3 packages in python.withPackages format";
    check = with types; (x: if isFunction x
      then isList (x pkgs.python3Packages)
      else false);
    merge = mergeOneOption;
  };

in

{
  options = {
    programs.neovim = {
      enable = mkEnableOption "Neovim";

      viAlias = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Symlink `vi` to `nvim` binary.
        '';
      };

      vimAlias = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Symlink `vim` to `nvim` binary.
        '';
      };

      withPython = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable Python 2 provider. Set to <literal>true</literal> to
          use Python 2 plugins.
        '';
      };

      extraPythonPackages = mkOption {
        type = with types; either extraPythonPackageType (listOf package);
        default = (_: []);
        defaultText = "ps: []";
        example = literalExample "(ps: with ps; [ pandas jedi ])";
        description = ''
          A function in python.withPackages format, which returns a 
          list of Python 2 packages required for your plugins to work.
        '';
      };

      withRuby = mkOption {
        type = types.nullOr types.bool;
        default = true;
        description = ''
          Enable ruby provider.
        '';
      };

      withPython3 = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable Python 3 provider. Set to <literal>true</literal> to
          use Python 3 plugins.
        '';
      };

      extraPython3Packages = mkOption {
        type = with types; either extraPython3PackageType (listOf package);
        default = (_: []);
        defaultText = "ps: []";
        example = literalExample "(ps: with ps; [ python-language-server ])";
        description = ''
          A function in python.withPackages format, which returns a 
          list of Python 3 packages required for your plugins to work.
        '';
      };

      configure = mkOption {
        type = types.attrs;
        default = {};
        example = literalExample ''
          configure = {
              customRC = $''''
              " here your custom configuration goes!
              $'''';
              packages.myVimPackage = with pkgs.vimPlugins; {
                # loaded on launch
                start = [ fugitive ];
                # manually loadable by calling `:packadd $plugin-name`
                opt = [ ];
              };
            };
        '';
        description = ''
          Generate your init file from your list of plugins and custom commands,
          and loads it from the store via <command>nvim -u /nix/store/hash-vimrc</command>
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.neovim.override {
        inherit (cfg)
          extraPython3Packages withPython3
          extraPythonPackages withPython
          withRuby viAlias vimAlias configure;
      })
    ];
  };
}
