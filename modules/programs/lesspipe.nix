{ config, lib, pkgs, ... }:

with lib;

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.lesspipe = {
      enable = mkEnableOption "lesspipe preprocessor for less";
    };
  };

  config = mkIf config.programs.lesspipe.enable {
    home.sessionVariables = {
      LESSOPEN = "|${pkgs.lesspipe}/bin/lesspipe.sh %s";
    };
  };
}
