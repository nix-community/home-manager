{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.anup;
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.anup = {
    enable = mkEnableOption "anup";
    package = mkPackageOption pkgs "anup" { nullable = true; };
    config = mkOption {
      type = with types; either str path;
      default = "";
      description = ''
        Config file for anup in RON (Rusty Object Notation) format.
        Available options can be found by looking at ~/.config/anup/config.ron.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    home.file.".config/anup/config.ron" = mkIf (cfg.config != "") {
      source = if lib.isPath cfg.config then cfg.config else pkgs.writeText "anup-config.ron" cfg.config;
    };
  };
}
