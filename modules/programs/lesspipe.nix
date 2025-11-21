{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.lesspipe;
in
{
  meta.maintainers = [ lib.maintainers.rycee ];

  options = {
    programs.lesspipe = {
      enable = lib.mkEnableOption "lesspipe preprocessor for less";

      package = lib.mkPackageOption pkgs "lesspipe" { };
    };
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      LESSOPEN = "|${cfg.package}/bin/lesspipe.sh %s";
    };
  };
}
