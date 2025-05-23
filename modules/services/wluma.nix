{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.wluma;
  format = pkgs.formats.toml { };
  configFile = format.generate "config.toml" cfg.settings;
in
{
  meta.maintainers = with lib.maintainers; [ _0x5a4 ];

  options.services.wluma = {
    enable = lib.mkEnableOption "Enable wluma, a service for automatic brightness adjustment";

    package = lib.mkPackageOption pkgs "wluma" { };

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
      };
      description = ''
        Configuration to use for wluma. See
        <https://github.com/maximbaz/wluma/blob/main/config.toml>
        for available options.
      '';
    };

    systemd.enable = lib.mkOption {
      description = "Wluma systemd integration";
      type = lib.types.bool;
      default = true;
    };

    systemd.target = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = config.wayland.systemd.target;
      defaultText = lib.literalExpression "config.wayland.systemd.target";
      example = "sway-session.target";
      description = ''
        The systemd target that will automatically start the Wluma service.

        When setting this value to `"sway-session.target"`,
        make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
        otherwise the service may never be started.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.wluma" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile = lib.mkIf (cfg.settings != { }) {
      "wluma/config.toml".source = configFile;
    };

    systemd.user.services.wluma = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "Automatic brightness adjustment based on screen contents and ALS ";
        After = [ cfg.systemd.target ];
        PartOf = [ cfg.systemd.target ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
        X-Restart-Triggers = lib.mkIf (cfg.settings != { }) [ "${configFile}" ];
      };

      Install.WantedBy = [ cfg.systemd.target ];

      Service = {
        ExecStart = lib.getExe cfg.package;
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
