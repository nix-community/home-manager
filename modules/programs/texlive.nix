{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.texlive;

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.texlive = {
      enable = mkEnableOption "Texlive";

      extraPackages = mkOption {
        default = self: {};
        example = literalExample ''
          tpkgs: { inherit (tpkgs) collection-fontsrecommended algorithms; }
        '';
        description = "Extra packages available to Texlive.";
      };

      package = mkOption {
        type = types.package;
        description = "Resulting customized Texlive package.";
        readOnly = true;
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    programs.texlive.package =
      pkgs.texlive.combine (cfg.extraPackages pkgs.texlive);
  };
}
