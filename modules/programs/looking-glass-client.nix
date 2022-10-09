{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.looking-glass-client;
  settingsFormat = pkgs.formats.ini { };
in {
  meta.maintainers = with maintainers; [ j-brn ];

  options.programs.looking-glass-client = {
    enable = mkEnableOption "looking-glass-client";

    package = mkOption {
      default = pkgs.looking-glass-client;
      defaultText = literalExpression "pkgs.looking-glass-client";
      type = types.package;
      example = literalExpression "pkgs.another-looking-glass-client-package";
      description = ''
        Looking-Glass-Client package to be used.
      '';
    };

    settings = mkOption {
      type = settingsFormat.type;
      default = { };
      description = "looking-glass-client settings";
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
    home.packages = [ cfg.package ];

    xdg.configFile."looking-glass/client.ini" =
      mkIf (cfg.settings != { }) {
        source = settingsFormat.generate ("looking-glass-client.ini")
          cfg.settings;
      };
  };
}
