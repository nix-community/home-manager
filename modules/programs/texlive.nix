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

        This module allows you to select which `pkgs.texlivePackages.*` you want to install.
        Start by editing {option}`programs.texlive.extraPackages`.

        If one of the pre-built common environments already suits you
        (e.g. `pkgs.texliveFull` or `pkgs.texliveMedium`),
        you do not need to use this module.
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
          tpkgs: with tpkgs; { # E.g. you can select from & combine
            # pre-built environments (e.g. this equals pkgs.texliveSmall)
            inherit scheme-small;
            # collection of smaller packages (similar granularity to packages in Linux distros like Debian)
            inherit collection-fontsrecommended;
            # or individual tex packages (corresponds in general to packages from CTAN & co.).
            inherit algorithms;
            # You can mix them however you see fit (overlaps should be no problem)
            inherit scheme-bookpub bibtex8 latexmk;
          }
        '';
        description = ''
          Extra packages which should be appended.

          {option}`programs.texlive.packageSet` will be passed to this function.
          In case you changed your `packageSet`,
          you can find all available packages to select from
          in nixpkgs under `pkgs.texlivePackages`,
          search [here for them](https://search.nixos.org/packages?type=packages&query=texlivePackages.).
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

    # note: cfg.enable states that this module’s only purpose is to customize the texlive environment
    home.packages = [ cfg.package ];

    programs.texlive.package = texlive.combine texlivePkgs;
  };
}
