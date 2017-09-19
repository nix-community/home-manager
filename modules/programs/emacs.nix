{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.emacs;

  # Copied from all-packages.nix.
  emacsPackages = pkgs.emacsPackagesNgGen cfg.package;
  emacsWithPackages = emacsPackages.emacsWithPackages;

in

{
  options = {
    programs.emacs = {
      enable = mkEnableOption "Emacs";

      package = mkOption {
        type = types.package;
        default = pkgs.emacs;
        defaultText = "pkgs.emacs";
        example = literalExample "pkgs.emacs25-nox";
        description = "The Emacs package to use.";
      };

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
    home.packages = [ (emacsWithPackages cfg.extraPackages) ];
  };
}
