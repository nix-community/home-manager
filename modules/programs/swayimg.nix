{ config, lib, pkgs, ... }:

let
  cfg = config.programs.swayimg;
  iniFormat = pkgs.formats.ini { };
in {
  meta.maintainers = with lib.maintainers; [ dod-101 ];

  options.programs.swayimg = {
    enable = lib.mkEnableOption "swayimg";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.swayimg;
      defaultText = lib.literalExpression "pkgs.swayimg";
      description = "The swayimg package to install";
    };
    settings = lib.mkOption {
      type = iniFormat.type;
      default = { };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/swayimg/config`. See <https://github.com/artemsen/swayimg/blob/master/extra/swayimgrc> for a list of available options.
      '';
      example = lib.literalExpression ''
        {
          viewer = {
            window = "#10000010";
            scale = "fill";
          };
          "info.viewer" = {
            top_left = "+name,+format";
          };
          "keys.viewer" = {
            "Shift+r" = "rand_file";
          };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.swayimg" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."swayimg/config" = lib.mkIf (cfg.settings != { }) {
      source = iniFormat.generate "config" cfg.settings;
    };
  };
}
