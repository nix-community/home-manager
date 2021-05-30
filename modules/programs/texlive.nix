{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.texlive;

  texlivePkgs = cfg.extraPackages pkgs.texlive;

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.texlive = {
      enable = mkEnableOption "TeX Live";

      extraPackages = mkOption {
        default = tpkgs: { inherit (tpkgs) collection-basic; };
        defaultText = "tpkgs: { inherit (tpkgs) collection-basic; }";
        example = literalExample ''
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

    programs.texlive.package = pkgs.texlive.combine texlivePkgs;
  };
}
