{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.lesspipe;

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.lesspipe = {
      enable = mkEnableOption "lesspipe preprocessor for less";

      package = mkPackageOption pkgs "lesspipe" { };
    };
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      LESSOPEN = "|${cfg.package}/bin/lesspipe.sh %s";
    };
  };
}
