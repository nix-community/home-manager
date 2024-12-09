{ pkgs, lib, config, ... }:

let

  cfg = config.services.swaync;

  jsonFormat = pkgs.formats.json { };

in {
  meta.maintainers = [ lib.hm.maintainers.abayomi185 ];

  options.services.swaync = {
    enable = lib.mkEnableOption "Swaync notification daemon";

    package = lib.mkPackageOption pkgs "swaynotificationcenter" { };

    style = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.path lib.types.lines);
      default = null;
      example = ''
        .notification-row {
          outline: none;
        }

        .notification-row:focus,
        .notification-row:hover {
          background: @noti-bg-focus;
        }

        .notification {
          border-radius: 12px;
          margin: 6px 12px;
          box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.3), 0 1px 3px 1px rgba(0, 0, 0, 0.7),
            0 2px 6px 2px rgba(0, 0, 0, 0.3);
          padding: 0;
        }
      '';
      description = ''
        CSS style of the bar. See
        <https://github.com/ErikReider/SwayNotificationCenter/blob/main/src/style.css>
        for the documentation.

        If the value is set to a path literal, then the path will be used as the CSS file.
      '';
    };

    settings = lib.mkOption {
      type = jsonFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          positionX = "right";
          positionY = "top";
          layer = "overlay";
          control-center-layer = "top";
          layer-shell = true;
          cssPriority = "application";
          control-center-margin-top = 0;
          control-center-margin-bottom = 0;
          control-center-margin-right = 0;
          control-center-margin-left = 0;
          notification-2fa-action = true;
          notification-inline-replies = false;
          notification-icon-size = 64;
          notification-body-image-height = 100;
          notification-body-image-width = 200;
        };
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/swaync/config.json`.
        See
        <https://github.com/ErikReider/SwayNotificationCenter/blob/main/src/configSchema.json>
        for the documentation.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # at-spi2-core is to minimize journalctl noise of:
    # "AT-SPI: Error retrieving accessibility bus address: org.freedesktop.DBus.Error.ServiceUnknown: The name org.a11y.Bus was not provided by any .service files"
    home.packages = [ cfg.package pkgs.at-spi2-core ];

    xdg.configFile = {
      "swaync/config.json".source =
        jsonFormat.generate "config.json" cfg.settings;
      "swaync/style.css" = lib.mkIf (cfg.style != null) {
        source = if builtins.isPath cfg.style || lib.isStorePath cfg.style then
          cfg.style
        else
          pkgs.writeText "swaync/style.css" cfg.style;
      };
    };

    systemd.user.services.swaync = {
      Unit = {
        Description = "Swaync notification daemon";
        Documentation = "https://github.com/ErikReider/SwayNotificationCenter";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session-pre.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };

      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";
        ExecStart = "${cfg.package}/bin/swaync";
        Restart = "on-failure";
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
