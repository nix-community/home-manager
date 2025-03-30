{ config, lib, pkgs, ... }:
let

  cfg = config.programs.obs-studio;

in {
  meta.maintainers = [ lib.maintainers.adisbladis ];

  options = {
    programs.obs-studio = {
      enable = lib.mkEnableOption "obs-studio";

      package = lib.mkPackageOption pkgs "obs-studio" { };

      finalPackage = lib.mkOption {
        type = lib.types.package;
        visible = false;
        readOnly = true;
        description = "Resulting customized OBS Studio package.";
      };

      plugins = lib.mkOption {
        default = [ ];
        example = lib.literalExpression "[ pkgs.obs-studio-plugins.wlrobs ]";
        description = "Optional OBS plugins.";
        type = lib.types.listOf lib.types.package;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.finalPackage ];
    programs.obs-studio.finalPackage =
      pkgs.wrapOBS.override { obs-studio = cfg.package; } {
        plugins = cfg.plugins;
      };
  };
}
