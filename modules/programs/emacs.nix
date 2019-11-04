{ config, lib, pkgs, ... }:

with lib;

let

  hmTypes = import ../lib/types.nix { inherit lib; };

  cfg = config.programs.emacs;

  # Copied from all-packages.nix, with modifications to support
  # overrides.
  emacsPackages =
    let
      epkgs = pkgs.emacsPackagesGen cfg.package;
    in
      epkgs.overrideScope' cfg.overrides;
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
        defaultText = literalExample "pkgs.emacs";
        example = literalExample "pkgs.emacs25-nox";
        description = "The Emacs package to use.";
      };

      extraPackages = mkOption {
        default = self: [];
        type = hmTypes.selectorFunction;
        defaultText = "epkgs: []";
        example = literalExample "epkgs: [ epkgs.emms epkgs.magit ]";
        description = ''
          Extra packages available to Emacs. To get a list of
          available packages run:
          <command>nix-env -f '&lt;nixpkgs&gt;' -qaP -A emacsPackages</command>.
        '';
      };

      overrides = mkOption {
        default = self: super: {};
        type = hmTypes.overlayFunction;
        defaultText = "self: super: {}";
        example = literalExample ''
          self: super: rec {
            haskell-mode = self.melpaPackages.haskell-mode;
            # ...
          };
        '';
        description = ''
          Allows overriding packages within the Emacs package set.
        '';
      };

      finalPackage = mkOption {
        type = types.package;
        visible = false;
        readOnly = true;
        description = ''
          The Emacs package including any overrides and extra packages.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.finalPackage ];
    programs.emacs.finalPackage = emacsWithPackages cfg.extraPackages;
  };
}
