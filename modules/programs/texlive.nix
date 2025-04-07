{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.programs.texlive;

  texlive = cfg.packageSet;
  texlivePkgs = cfg.extraPackages texlive;

in
{
  meta.maintainers = [ lib.maintainers.rycee ];

  options = {
    programs.texlive = {
      enable = lib.mkEnableOption "TeX Live";

      packageSet = mkOption {
        default = pkgs.texlive;
        defaultText = lib.literalExpression "pkgs.texlive";
        description = "TeX Live package set to use.";
      };

      extraPackages = mkOption {
        default = tpkgs: { inherit (tpkgs) collection-basic; };
        defaultText = "tpkgs: { inherit (tpkgs) collection-basic; }";
        example = lib.literalExpression ''
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

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = texlivePkgs != { };
        message = "Must provide at least one extra package in" + " 'programs.texlive.extraPackages'.";
      }
    ];

    home.packages = [ cfg.package ];

    programs.texlive.package = texlive.combine texlivePkgs;
  };
}
