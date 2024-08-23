{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.texlive;

  texlive = cfg.packageSet;
  texlivePkgs = cfg.extraPackages texlive;

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.texlive = {
      enable = mkEnableOption ''
        TeX Live package customization.

        This module allows you to select which texlive packages you want to install.
        Start by exteding {option}`programs.texlive.extraPackages`.
      '';

      packageSet = mkOption {
        default = pkgs.texlive;
        defaultText = literalExpression ''
          pkgs.texlive  # corresponds to packages in pkgs.texlivePackages
        '';
        description = ''
          TeX Live package set to use.

          This is used in the option {option}`programs.texlive.extraPackages`.
          Normally you do not want to change this from the default
          except if you want to use texlive packages from a different nixpkgs release than your config’s default.
        '';
      };

      extraPackages = mkOption {
        default = tpkgs: { inherit (tpkgs) collection-basic; };
        defaultText = "tpkgs: { inherit (tpkgs) collection-basic; }";
        example = literalExpression ''
          tpkgs: { inherit (tpkgs) collection-fontsrecommended algorithms; }
        '';
        description = ''
          Extra packages which should be appended.

          {option}`programs.texlive.packageSet` will be passed to this function.
          In case you changed your `packageSet`,
          you can find all available packages to select from
          in nixpkgs under `pkgs.texlivePackages`,
          see [here to search for them in the latest release](https://search.nixos.org/packages?type=packages&query=texlivePackages.).
        '';
      };

      package = mkOption {
        type = types.package;
        description = "Resulting customized TeX Live package.";
        readOnly = true;
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = texlivePkgs != { };
      message = "Must provide at least one extra package in"
        + " 'programs.texlive.extraPackages'.";
    }];

    home.packages = [ cfg.package ];

    programs.texlive.package = texlive.combine texlivePkgs;
  };
}
