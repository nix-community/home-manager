{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.obs-studio;

in {
  meta.maintainers = [ maintainers.adisbladis ];

  options = {
    programs.obs-studio = {
      enable = mkEnableOption "obs-studio";

      package = lib.mkPackageOption pkgs "obs-studio" { };

      finalPackage = mkOption {
        type = types.package;
        visible = false;
        readOnly = true;
        description = "Resulting customized OBS Studio package.";
      };

      plugins = mkOption {
        default = [ ];
        example = literalExpression "[ pkgs.obs-studio-plugins.wlrobs ]";
        description = "Optional OBS plugins.";
        type = types.listOf types.package;
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.finalPackage ];
    programs.obs-studio.finalPackage =
      pkgs.wrapOBS.override { obs-studio = cfg.package; } {
        plugins = cfg.plugins;
      };
  };
}
