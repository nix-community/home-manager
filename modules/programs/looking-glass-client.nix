{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.looking-glass-client;
  settingsFormat = pkgs.formats.ini { };
in {
  meta.maintainers = with maintainers; [ j-brn ];

  options.programs.looking-glass-client = {
    enable = mkEnableOption "looking-glass-client";

    package = mkPackageOption pkgs "looking-glass-client" { };

    settings = mkOption {
      type = settingsFormat.type;
      default = { };
      description = "looking-glass-client settings.";
      example = literalExpression ''
        {
          app = {
            allowDMA = true;
            shmFile = "/dev/kvmfr0";
          };

          win = {
            fullScreen = true;
            showFPS = false;
            jitRender = true;
          };

          spice = {
            enable = true;
            audio = true;
          };

          input = {
            rawMouse = true;
            escapeKey = 62;
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "programs.looking-glass-client" pkgs
        platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."looking-glass/client.ini" = mkIf (cfg.settings != { }) {
      source =
        settingsFormat.generate ("looking-glass-client.ini") cfg.settings;
    };
  };
}
