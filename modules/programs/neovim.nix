{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.neovim;

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
        type = types.listOf types.package;
        default = [ ];
        example = literalExample "with pkgs.python2Packages; [ pandas jedi ]";
        description = ''
          List here Python 2 packages required for your plugins to
          work.
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
        type = types.listOf types.package;
        default = [ ];
        example = literalExample
          "with pkgs.python3Packages; [ python-language-server ]";
        description = ''
          List here Python 3 packages required for your plugins to work.
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
          withPython3 withPython
          withRuby viAlias vimAlias configure;
	  extraPython3Packages = (_: cfg.extraPython3Packages);
	  extraPythonPackages = (_: cfg.extraPythonPackages);
      })
    ];
  };
}
