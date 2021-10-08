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
      enable = mkEnableOption "TeX Live";

      packageSet = mkOption {
        default = pkgs.texlive;
        defaultText = literalExpression "pkgs.texlive";
        description = "TeX Live package set to use.";
      };

      extraPackages = mkOption {
        default = tpkgs: { inherit (tpkgs) collection-basic; };
        defaultText = "tpkgs: { inherit (tpkgs) collection-basic; }";
        example = literalExpression ''
          tpkgs: { inherit (tpkgs) collection-fontsrecommended algorithms; }
        '';
        description = "Extra packages available to TeX Live.";
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
