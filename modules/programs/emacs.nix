{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.emacs;

in

{
  options = {
    programs.emacs = {
      enable = mkEnableOption "Emacs";

      extraPackages = mkOption {
        default = self: [];
        example = literalExample ''
          epkgs: [ epkgs.emms epkgs.magit ]
        '';
        description = "Extra packages available to Emacs.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ (pkgs.emacsWithPackages cfg.extraPackages) ];
  };
}
