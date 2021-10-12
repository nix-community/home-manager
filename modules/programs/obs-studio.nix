{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.obs-studio;

in {
  meta.maintainers = [ maintainers.adisbladis ];

  options = {
    programs.obs-studio = {
      enable = mkEnableOption "obs-studio";

      package = mkOption {
        type = types.package;
        default = pkgs.obs-studio;
        defaultText = literalExpression "pkgs.obs-studio";
        description = ''
          OBS Studio package to install.
        '';
      };

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
