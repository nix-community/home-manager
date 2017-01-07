{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.texlive;

in

{
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
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.texlive.combine (cfg.extraPackages pkgs.texlive))
    ];

  };
}
