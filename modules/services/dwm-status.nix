{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.dwm-status;

  jsonFormat = pkgs.formats.json { };

  features = [ "audio" "backlight" "battery" "cpu_load" "network" "time" ];

  finalConfig = { inherit (cfg) order; } // cfg.extraConfig;

  configFile = jsonFormat.generate "dwm-status.json" finalConfig;

in {
  options = {
    services.dwm-status = {
      enable = mkEnableOption "dwm-status user service";

      package = mkOption {
        type = types.package;
        default = pkgs.dwm-status;
        defaultText = literalExpression "pkgs.dwm-status";
        example = "pkgs.dwm-status.override { enableAlsaUtils = false; }";
        description = "Which dwm-status package to use.";
      };

      order = mkOption {
        type = types.listOf (types.enum features);
        description = "List of enabled features in order.";
      };

      extraConfig = mkOption {
        type = jsonFormat.type;
        default = { };
        example = literalExpression ''
          {
            separator = "#";

            battery = {
              notifier_levels = [ 2 5 10 15 20 ];
            };

            time = {
              format = "%H:%M";
            };
          }
        '';
        description = "Extra config of dwm-status.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.dwm-status" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.dwm-status = {
      Unit = {
        Description = "DWM status service";
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = { ExecStart = "${cfg.package}/bin/dwm-status ${configFile}"; };
    };
  };
}
