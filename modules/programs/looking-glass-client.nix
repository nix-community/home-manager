{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.looking-glass-client;
  settingsFormat = pkgs.formats.ini { };
in
{
  meta.maintainers = with lib.maintainers; [ j-brn ];

  options.programs.looking-glass-client = {
    enable = lib.mkEnableOption "looking-glass-client";

    package = lib.mkPackageOption pkgs "looking-glass-client" { nullable = true; };

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = { };
      description = "looking-glass-client settings.";
      example = lib.literalExpression ''
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

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.looking-glass-client" pkgs lib.platforms.linux)
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."looking-glass/client.ini" = lib.mkIf (cfg.settings != { }) {
      source = settingsFormat.generate "looking-glass-client.ini" cfg.settings;
    };
  };
}
