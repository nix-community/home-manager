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
        type = types.nullOr types.bool;
        default = true;
        description = ''
          Enable python 2 provider. Set to true to use python 2 plugins.
        '';
      };

      extraPythonPackages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        example = literalExample ''
          [ pandas jedi ]
        '';
        description = ''
          List here python 2 packages required for your plugins to work.
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
        type = types.nullOr types.bool;
        default = true;
        description = ''
          Enable python 3 provider. Set to true to use python 3 plugins.
        '';
      };

      extraPython3Packages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        example = ''
          [ python-language-server ]
        '';
        description = ''
          List here python 3 packages required for your plugins to work.
        '';
      };
    };
  };

  config =
    let
      neovim = pkgs.neovim.override {
        inherit (cfg) extraPython3Packages withPython3 extraPythonPackages withPython withRuby;
      };
    in mkIf cfg.enable rec {
      home.packages = [ neovim ];
    };
}

