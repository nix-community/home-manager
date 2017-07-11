{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.home-manager;

in

{
  options = {
    programs.home-manager = {
      enable = mkEnableOption "Home Manager";

      modulesPath = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "$HOME/devel/home-manager/modules";
        description = ''
          The default path to use for Home Manager modules. If this
          path does not exist then
          <filename>$HOME/.config/nixpkgs/home-manager/modules</filename>
          and <filename>$HOME/.nixpkgs/home-manager/modules</filename>
          will be attempted.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      (import ../../home-manager {
        inherit pkgs;
        inherit (cfg) modulesPath;
      })
    ];
  };
}
