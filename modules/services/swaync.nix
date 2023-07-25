{ pkgs, lib, config, ... }:
let
  cfg = config.services.swaync;
  settingsFormat = pkgs.formats.json { };

  settings = cfg.settings // { "$schema" = cfg.schema; };
  configFile =
    (settingsFormat.generate "swaync/config.json" settings).overrideAttrs (_:
      {
        # TODO uncomment once version higher than 0.9.0
        # checkPhase = "${pkgs.check-jsonschema}/bin/check-jsonschema --schemafile ${settings."$schema"} $out ";
      });
in {
  meta.maintainers = [ lib.maintainers.rhoriguchi ];

  options.services.swaync = {
    enable = lib.mkEnableOption "Swaync notification daemon";

    package = lib.mkPackageOption pkgs "swaynotificationcenter" { };

    systemd = {
      enable = lib.mkEnableOption "Systemd integration";

      target = lib.mkOption {
        type = lib.types.str;
        default = "graphical-session.target";
        example = "sway-session.target";
        description = ''
          Systemd target to bind to.
        '';
      };
    };

    style = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.path lib.types.lines);
      default = null;
      description = ''
        CSS style of the bar. See https://github.com/ErikReider/SwayNotificationCenter/blob/main/src/style.css for
        the documentation.

        If the value is set to a path literal, then the path will be used as the CSS file.
      '';
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
    };

    schema = lib.mkOption {
      default = "${cfg.package}/etc/xdg/swaync/configSchema.json";
      type = lib.types.path;
      description = lib.mdDoc ''
        Schema to validate the configuration.
      '';
    };

    settings = lib.mkOption {
      default = { };
      type = settingsFormat.type;
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/swaync/config.json`.
        See https://github.com/ErikReider/SwayNotificationCenter/blob/main/src/configSchema.json for the documentation.
      '';
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
          notification-body-image-width = 200
        };
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # at-spi2-core is to minimize journalctl noise of:
    # "AT-SPI: Error retrieving accessibility bus address: org.freedesktop.DBus.Error.ServiceUnknown: The name org.a11y.Bus was not provided by any .service files"
    home.packages = [ cfg.package pkgs.at-spi2-core ];

    xdg.configFile = {
      "swaync/config.json".source = configFile;
      "swaync/style.css" = lib.mkIf (cfg.style != null) {
        source = if builtins.isPath cfg.style || lib.isStorePath cfg.style then
          cfg.style
        else
          pkgs.writeText "swaync/style.css" cfg.style;
      };
    };

    systemd.user.services.swaync = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "Swaync notification daemon";
        Documentation = "https://github.com/ErikReider/SwayNotificationCenter";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session-pre.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";

        X-Restart-Triggers =
          [ "${config.xdg.configFile."swaync/config.json".source}" ]
          ++ lib.optional (cfg.style != null)
          "${config.xdg.configFile."swaync/style.css".source}";
      };

      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";
        ExecStart = "${cfg.package}/bin/swaync";
        ExecReload = [ "${cfg.package}/bin/swaync-client --reload-config" ]
          ++ lib.optional (cfg.style != null)
          "${cfg.package}/bin/swaync-client --reload-css";
        Restart = "on-failure";
      };

      Install.WantedBy = [ cfg.systemd.target ];
    };
  };
}
