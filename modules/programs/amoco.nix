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

  cfg = config.programs.amoco;
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.amoco = {
    enable = mkEnableOption "amoco";
    package = mkPackageOption pkgs "amoco" { nullable = true; };
    config = mkOption {
      type = with types; either str path;
      default = "";
      description = ''
        Config file for amoco as a Python configuration module.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    home.file.".config/amoco/config" = mkIf (cfg.config != "") {
      source = if lib.isPath cfg.config then cfg.config else pkgs.writeText "amoco-config" cfg.config;
    };
  };
}
