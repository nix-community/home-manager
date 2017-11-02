{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.neovim;

in

{
  options = {
    programs.neovim = {
      enable = mkEnableOption "Neovim";

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
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.neovim.override {
        inherit (cfg)
          extraPython3Packages withPython3
          extraPythonPackages withPython
          withRuby;
      })
    ];
  };
}
