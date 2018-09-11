{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.emacs;

  # Copied from all-packages.nix.
  emacsPackages = pkgs.emacsPackagesNgGen cfg.package;
  emacsWithPackages = emacsPackages.emacsWithPackages;

in

{
  meta.maintainers = [ maintainers.rycee ];

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
        defaultText = "epkgs: []";
        example = literalExample "epkgs: [ epkgs.emms epkgs.magit ]";
        description = "Extra packages available to Emacs.";
      };

      finalPackage = mkOption {
        type = types.package;
        internal = true;
        readOnly = true;
        description = "The Emacs package including any extra packages.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.finalPackage ];

    programs.emacs.finalPackage = emacsWithPackages cfg.extraPackages;
  };
}
