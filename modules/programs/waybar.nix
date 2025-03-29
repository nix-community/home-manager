{ config, lib, pkgs, ... }:

let
  inherit (lib)
    all filterAttrs hasAttr isStorePath literalExpression optional optionalAttrs
    types;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf mkMerge;

  cfg = config.programs.waybar;

  jsonFormat = pkgs.formats.json { };

  mkMargin = name:
    mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 10;
      description = "Margin value without unit.";
    };

  waybarBarConfig = with types;
    submodule {
      freeformType = jsonFormat.type;

      options = {
        layer = mkOption {
          type = nullOr (enum [ "top" "bottom" "overlay" ]);
          default = null;
          description = ''
            Decide if the bar is displayed in front (`"top"`)
            of the windows or behind (`"bottom"`).
          '';
          example = "top";
        };

        output = mkOption {
          type = nullOr (either str (listOf str));
          default = null;
          example = literalExpression ''
            [ "DP-1" "!DP-2" "!DP-3" ]
          '';
          description = ''
            Specifies on which screen this bar will be displayed.
            Exclamation mark(!) can be used to exclude specific output.
          '';
        };

        position = mkOption {
          type = nullOr (enum [ "top" "bottom" "left" "right" ]);
          default = null;
          example = "right";
          description = "Bar position relative to the output.";
        };

        height = mkOption {
          type = nullOr ints.unsigned;
          default = null;
          example = 5;
          description =
            "Height to be used by the bar if possible. Leave blank for a dynamic value.";
        };

        width = mkOption {
          type = nullOr ints.unsigned;
          default = null;
          example = 5;
          description =
            "Width to be used by the bar if possible. Leave blank for a dynamic value.";
        };

        modules-left = mkOption {
          type = nullOr (listOf str);
          default = null;
          description = "Modules that will be displayed on the left.";
          example = literalExpression ''
            [ "sway/workspaces" "sway/mode" "wlr/taskbar" ]
          '';
        };

        modules-center = mkOption {
          type = nullOr (listOf str);
          default = null;
          description = "Modules that will be displayed in the center.";
          example = literalExpression ''
            [ "sway/window" ]
          '';
        };

        modules-right = mkOption {
          type = nullOr (listOf str);
          default = null;
          description = "Modules that will be displayed on the right.";
          example = literalExpression ''
            [ "mpd" "custom/mymodule#with-css-id" "temperature" ]
          '';
        };

        modules = mkOption {
          type = jsonFormat.type;
          visible = false;
          default = null;
          description = "Modules configuration.";
          example = literalExpression ''
            {
              "sway/window" = {
                max-length = 50;
              };
              "clock" = {
                format-alt = "{:%a, %d. %b  %H:%M}";
              };
            }
          '';
        };

        margin = mkOption {
          type = nullOr str;
          default = null;
          description = "Margins value using the CSS format without units.";
          example = "20 5";
        };

        margin-left = mkMargin "left";
        margin-right = mkMargin "right";
        margin-bottom = mkMargin "bottom";
        margin-top = mkMargin "top";

        name = mkOption {
          type = nullOr str;
          default = null;
          description =
            "Optional name added as a CSS class, for styling multiple waybars.";
          example = "waybar-1";
        };

        gtk-layer-shell = mkOption {
          type = nullOr bool;
          default = null;
          example = false;
          description =
            "Option to disable the use of gtk-layer-shell for popups.";
        };
      };
    };
in {
  meta.maintainers = with lib.maintainers; [ berbiche khaneliman ];

  options.programs.waybar = with lib.types; {
    enable = mkEnableOption "Waybar";

    package = mkOption {
      type = package;
      default = pkgs.waybar;
      defaultText = literalExpression "pkgs.waybar";
      description = ''
        Waybar package to use. Set to `null` to use the default package.
      '';
    };

    settings = mkOption {
      type = either (listOf waybarBarConfig) (attrsOf waybarBarConfig);
      default = [ ];
      description = ''
        Configuration for Waybar, see <https://github.com/Alexays/Waybar/wiki/Configuration>
        for supported values.
      '';
      example = literalExpression ''
        {
          mainBar = {
            layer = "top";
            position = "top";
            height = 30;
            output = [
              "eDP-1"
              "HDMI-A-1"
            ];
            modules-left = [ "sway/workspaces" "sway/mode" "wlr/taskbar" ];
            modules-center = [ "sway/window" "custom/hello-from-waybar" ];
            modules-right = [ "mpd" "custom/mymodule#with-css-id" "temperature" ];

            "sway/workspaces" = {
              disable-scroll = true;
              all-outputs = true;
            };
            "custom/hello-from-waybar" = {
              format = "hello {}";
              max-length = 40;
              interval = "once";
              exec = pkgs.writeShellScript "hello-from-waybar" '''
                echo "from within waybar"
              ''';
            };
          };
        }
      '';
    };

    systemd.enable = mkEnableOption "Waybar systemd integration";

    systemd.target = mkOption {
      type = nullOr str;
      default = config.wayland.systemd.target;
      defaultText = literalExpression "config.wayland.systemd.target";
      example = "sway-session.target";
      description = ''
        The systemd target that will automatically start the Waybar service.

        When setting this value to `"sway-session.target"`,
        make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
        otherwise the service may never be started.
      '';
    };

    systemd.enableInspect = mkOption {
      type = bool;
      default = false;
      example = true;
      description = ''
        Inspect objects and find their CSS classes, experiment with live CSS styles, and lookup the current value of CSS properties.

        See <https://developer.gnome.org/documentation/tools/inspector.html>
      '';
    };

    style = mkOption {
      type = nullOr (either path lines);
      default = null;
      description = ''
        CSS style of the bar.

        See <https://github.com/Alexays/Waybar/wiki/Configuration>
        for the documentation.

        If the value is set to a path literal, then the path will be used as the css file.
      '';
      example = ''
        * {
          border: none;
          border-radius: 0;
          font-family: Source Code Pro;
        }
        window#waybar {
          background: #16191C;
          color: #AAB2BF;
        }
        #workspaces button {
          padding: 0 5px;
        }
      '';
    };
  };

  config = let
    # Removes nulls because Waybar ignores them.
    # This is not recursive.
    removeTopLevelNulls = filterAttrs (_: v: v != null);

    # Makes the actual valid configuration Waybar accepts
    # (strips our custom settings before converting to JSON)
    makeConfiguration = configuration:
      let
        # The "modules" option is not valid in the JSON
        # as its descendants have to live at the top-level
        settingsWithoutModules = removeAttrs configuration [ "modules" ];
        settingsModules =
          optionalAttrs (configuration.modules != null) configuration.modules;
      in removeTopLevelNulls (settingsWithoutModules // settingsModules);

    # Allow using attrs for settings instead of a list in order to more easily override
    settings = if builtins.isAttrs cfg.settings then
      lib.attrValues cfg.settings
    else
      cfg.settings;

    # The clean list of configurations
    finalConfiguration = map makeConfiguration settings;

    configSource = jsonFormat.generate "waybar-config.json" finalConfiguration;

  in mkIf cfg.enable (mkMerge [
    {
      assertions = [
        (lib.hm.assertions.assertPlatform "programs.waybar" pkgs
          lib.platforms.linux)
        ({
          assertion =
            if lib.versionAtLeast config.home.stateVersion "22.05" then
              all (x: !hasAttr "modules" x || x.modules == null) settings
            else
              true;
          message = ''
            The `programs.waybar.settings.[].modules` option has been removed.
            It is now possible to declare modules in the configuration without nesting them under the `modules` option.
          '';
        })
      ];

      home.packages = [ cfg.package ];

      xdg.configFile."waybar/config" = mkIf (settings != [ ]) {
        source = configSource;
        onChange = ''
          ${pkgs.procps}/bin/pkill -u $USER -USR2 waybar || true
        '';
      };

      xdg.configFile."waybar/style.css" = mkIf (cfg.style != null) {
        source = if builtins.isPath cfg.style || isStorePath cfg.style then
          cfg.style
        else
          pkgs.writeText "waybar/style.css" cfg.style;
        onChange = ''
          ${pkgs.procps}/bin/pkill -u $USER -USR2 waybar || true
        '';
      };
    }

    (mkIf cfg.systemd.enable {
      systemd.user.services.waybar = {
        Unit = {
          Description =
            "Highly customizable Wayland bar for Sway and Wlroots based compositors.";
          Documentation = "https://github.com/Alexays/Waybar/wiki";
          PartOf = [ cfg.systemd.target "tray.target" ];
          After = [ cfg.systemd.target ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
          X-Restart-Triggers = optional (settings != [ ])
            "${config.xdg.configFile."waybar/config".source}"
            ++ optional (cfg.style != null)
            "${config.xdg.configFile."waybar/style.css".source}";
        };

        Service = {
          ExecStart = "${cfg.package}/bin/waybar";
          ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
          Restart = "on-failure";
          KillMode = "mixed";
        } // optionalAttrs cfg.systemd.enableInspect {
          Environment = [ "GTK_DEBUG=interactive" ];
        };

        Install.WantedBy = [ "tray.target" ]
          ++ lib.optional (cfg.systemd.target != null) cfg.systemd.target;
      };
    })
  ]);
}
