{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.swayimg;
  iniFormat = pkgs.formats.ini { };
in {
  meta.maintainers = with lib.maintainers; [ dod-101 ];

  options.programs.swayimg = {
    enable = mkEnableOption "swayimg";
    package = mkOption {
      type = types.package;
      default = pkgs.swayimg;
      defaultText = literalExpression "pkgs.swayimg";
      description = "The swayimg package to install";
    };
    settings = mkOption {
      type = iniFormat.type;
      default = { };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/swayimg/config`. See <https://github.com/artemsen/swayimg/blob/master/extra/swayimgrc> for a list of available options.
      '';
      example = literalExpression ''
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

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "programs.swayimg" pkgs platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."swayimg/config" = mkIf (cfg.settings != { }) {
      source = iniFormat.generate "config" cfg.settings;
    };
  };
}
