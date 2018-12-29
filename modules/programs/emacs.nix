{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.emacs;

  # Copied from all-packages.nix, with modifications to support
  # overrides.
  emacsPackages =
    let
      epkgs = pkgs.emacsPackagesNgGen cfg.package;
    in
      epkgs.overrideScope' cfg.overrides;
  emacsWithPackages = emacsPackages.emacsWithPackages;

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.emacs = {
      enable = mkEnableOption "Emacs";
      service = mkEnableOption "Emacs daemon systemd service";

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

      overrides = mkOption {
        default = self: super: {};
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

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ cfg.finalPackage ];
      programs.emacs.finalPackage = emacsWithPackages cfg.extraPackages;
    }

    (mkIf cfg.service {
      systemd.user.services.emacs = {
        Unit = {
          Description = "Emacs: the extensible, self-documenting text editor";
          Documentation = "info:emacs man:emacs(1) https://gnu.org/software/emacs/";
        };

        Service = {
          Type = "simple";
          ExecStart = "${pkgs.stdenv.shell} -l -c 'exec ${cfg.finalPackage}/bin/emacs --fg-daemon'";
          ExecStop = "${cfg.finalPackage}/bin/emacsclient --eval '(kill-emacs)'";
          Restart = "on-failure";
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    })
  ]);
}
