{ config, lib, pkgs, ... }:
let
  cfg = config.services.wluma;
  format = pkgs.formats.toml { };
  configFile = format.generate "config.toml" cfg.settings;
in {
  meta.maintainers = [ lib.maintainers.aktaboot ];

  options.services.wluma = {
    enable = lib.mkEnableOption "wluma";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.wluma;
      defaultText = lib.literalExpression "pkgs.wluma";
      description = "Package providing {command}`wluma`.";
    };

    settings = lib.mkOption {
      type = format.type;
      default = { };
      example = {
        als.iio = {
          path = "";
          thresholds = {
            "0" = "night";
            "20" = "dark";
            "80" = "dim";
            "250" = "normal";
            "500" = "bright";
            "800" = "outdoors";
          };
        };
        output.backlight = [{
          name = "eDP-1";
          path = "/sys/class/backlight/intel_backlight";
          capturer = "wlroots";
        }];
        keyboard = [{
          name = "keyboard-dell";
          path =
            "/sys/bus/platform/devices/dell-laptop/leds/dell::kbd_backlight";
        }];
      };
      description = ''
        Configuration to use for wluma. See
        <https://github.com/maximbaz/wluma/blob/main/config.toml>
        for available options.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.wluma" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile = lib.mkIf (cfg.settings != { }) {
      "wluma/config.toml".source = configFile;
    };

    systemd.user.services.wluma = {
      Unit = {
        Description =
          "Adjusting screen brightness based on screen contents and amount of ambient light";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        X-Restart-Triggers = lib.mkIf (cfg.settings != { }) [ "${configFile}" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        ExecStart = "${cfg.package}/bin/wluma";
        Restart = "always";

        # Sandboxing.
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateUsers = true;
        RestrictNamespaces = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = "@system-service";
      };
    };
  };
}
