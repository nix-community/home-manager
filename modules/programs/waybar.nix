{ config, lib, pkgs, ... }:

let
  inherit (lib)
    any attrByPath attrNames concatMap concatMapStringsSep elem elemAt filter
    filterAttrs flip foldl' hasPrefix head length mergeAttrs optionalAttrs
    stringLength subtractLists types unique;
  inherit (lib.options) literalExample mkEnableOption mkOption;
  inherit (lib.modules) mkIf mkMerge;

  cfg = config.programs.waybar;

  # Used when generating warnings
  modulesPath = "programs.waybar.settings.[].modules";

  jsonFormat = pkgs.formats.json { };

  # Taken from <https://github.com/Alexays/Waybar/blob/cc3acf8102c71d470b00fd55126aef4fb335f728/src/factory.cpp> (2020/10/10)
  # Order is preserved from the file for easier matching
  defaultModuleNames = [
    "battery"
    "sway/mode"
    "sway/workspaces"
    "sway/window"
    "sway/language"
    "wlr/taskbar"
    "river/tags"
    "idle_inhibitor"
    "memory"
    "cpu"
    "clock"
    "disk"
    "tray"
    "network"
    "backlight"
    "pulseaudio"
    "mpd"
    "sndio"
    "temperature"
    "bluetooth"
  ];

  # Allow specifying a CSS id after the default module name
  isValidDefaultModuleName = x:
    any (name:
      let
        res = builtins.split name x;
        # if exact match of default module name
      in if res == [ "" [ ] ] || res == [ "" [ ] "" ] then
        true
      else
        head res == "" && length res >= 3 && hasPrefix "#" (elemAt res 2))
    defaultModuleNames;

  isValidCustomModuleName = x: hasPrefix "custom/" x && stringLength x > 7;

  margins = let
    mkMargin = name: {
      "margin-${name}" = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 10;
        description = "Margins value without unit.";
      };
    };
    margins = map mkMargin [ "top" "left" "bottom" "right" ];
  in foldl' mergeAttrs { } margins;

  waybarBarConfig = with lib.types;
    submodule {
      options = {
        layer = mkOption {
          type = nullOr (enum [ "top" "bottom" ]);
          default = null;
          description = ''
            Decide if the bar is displayed in front (<code>"top"</code>)
            of the windows or behind (<code>"bottom"</code>).
          '';
          example = "top";
        };

        output = mkOption {
          type = nullOr (either str (listOf str));
          default = null;
          example = literalExample ''
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
          type = listOf str;
          default = [ ];
          description = "Modules that will be displayed on the left.";
          example = literalExample ''
            [ "sway/workspaces" "sway/mode" "wlr/taskbar" ]
          '';
        };

        modules-center = mkOption {
          type = listOf str;
          default = [ ];
          description = "Modules that will be displayed in the center.";
          example = literalExample ''
            [ "sway/window" ]
          '';
        };

        modules-right = mkOption {
          type = listOf str;
          default = [ ];
          description = "Modules that will be displayed on the right.";
          example = literalExample ''
            [ "mpd" "custom/mymodule#with-css-id" "temperature" ]
          '';
        };

        modules = mkOption {
          type = jsonFormat.type;
          default = { };
          description = "Modules configuration.";
          example = literalExample ''
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

        inherit (margins) margin-top margin-left margin-bottom margin-right;

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
  meta.maintainers = with lib.maintainers; [ berbiche ];

  options.programs.waybar = with lib.types; {
    enable = mkEnableOption "Waybar";

    package = mkOption {
      type = package;
      default = pkgs.waybar;
      defaultText = "pkgs.waybar";
      description = ''
        Waybar package to use. Set to <code>null</code> to use the default module.
      '';
    };

    settings = mkOption {
      type = listOf waybarBarConfig;
      default = [ ];
      description = ''
        Configuration for Waybar, see <link
          xlink:href="https://github.com/Alexays/Waybar/wiki/Configuration"/>
        for supported values.
      '';
      example = literalExample ''
        [
          {
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
            modules = {
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
        ]
      '';
    };

    systemd.enable = mkEnableOption "Waybar systemd integration";

    style = mkOption {
      type = nullOr str;
      default = null;
      description = ''
        CSS style of the bar.
        See <link xlink:href="https://github.com/Alexays/Waybar/wiki/Configuration"/>
        for the documentation.
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
    writePrettyJSON = jsonFormat.generate;

    configSource = let
      # Removes nulls because Waybar ignores them for most values
      removeNulls = filterAttrs (_: v: v != null);

      # Makes the actual valid configuration Waybar accepts
      # (strips our custom settings before converting to JSON)
      makeConfiguration = configuration:
        let
          # The "modules" option is not valid in the JSON
          # as its descendants have to live at the top-level
          settingsWithoutModules = removeAttrs configuration [ "modules" ];
          settingsModules =
            optionalAttrs (configuration.modules != { }) configuration.modules;
        in removeNulls (settingsWithoutModules // settingsModules);
      # The clean list of configurations
      finalConfiguration = map makeConfiguration cfg.settings;
    in writePrettyJSON "waybar-config.json" finalConfiguration;

    #
    # Warnings are generated based on the following things:
    # 1. A `module` is referenced in any of `modules-{left,center,right}` that is neither
    #    a default module name nor defined in `modules`.
    # 2. A `module` is defined in `modules` but is not referenced in either of
    #    `modules-{left,center,right}`.
    # 3. A custom `module` configuration is defined in `modules` but has an invalid name
    #    for a custom module (i.e. not "custom/my-module-name").
    #
    warnings = let
      mkUnreferencedModuleWarning = name:
        "The module '${name}' defined in '${modulesPath}' is not referenced "
        + "in either `modules-left`, `modules-center` or `modules-right` of Waybar's options";
      mkUndefinedModuleWarning = settings: name:
        let
          # Locations where the module is undefined (a combination modules-{left,center,right})
          locations = flip filter [ "left" "center" "right" ]
            (x: elem name settings."modules-${x}");
          mkPath = loc: "'${modulesPath}-${loc}'";
          # The modules-{left,center,right} configuration that includes
          # an undefined module
          path = concatMapStringsSep " and " mkPath locations;
        in "The module '${name}' defined in ${path} is neither "
        + "a default module or a custom module declared in '${modulesPath}'";
      mkInvalidModuleNameWarning = name:
        "The custom module '${name}' defined in '${modulesPath}' is not a valid "
        + "module name. A custom module's name must start with 'custom/' "
        + "like 'custom/mymodule' for instance";

      allFaultyModules = flip map cfg.settings (settings:
        let
          allModules = unique
            (concatMap (x: attrByPath [ "modules-${x}" ] [ ] settings) [
              "left"
              "center"
              "right"
            ]);
          declaredModules = attrNames settings.modules;
          # Modules declared in `modules` but not referenced in `modules-{left,center,right}`
          unreferencedModules = subtractLists allModules declaredModules;
          # Modules listed in modules-{left,center,right} that are not default modules
          nonDefaultModules =
            filter (x: !isValidDefaultModuleName x) allModules;
          # Modules referenced in `modules-{left,center,right}` but not declared in `modules`
          undefinedModules = subtractLists declaredModules nonDefaultModules;
          # Check for invalid module names
          invalidModuleNames = filter
            (m: !isValidCustomModuleName m && !isValidDefaultModuleName m)
            declaredModules;
        in {
          # The Waybar bar configuration (since config.settings is a list)
          inherit settings;
          undef = undefinedModules;
          unref = unreferencedModules;
          invalidName = invalidModuleNames;
        });

      allWarnings = flip concatMap allFaultyModules
        ({ settings, undef, unref, invalidName }:
          let
            unreferenced = map mkUnreferencedModuleWarning unref;
            undefined = map (mkUndefinedModuleWarning settings) undef;
            invalid = map mkInvalidModuleNameWarning invalidName;
          in undefined ++ unreferenced ++ invalid);
    in allWarnings;

  in mkIf cfg.enable (mkMerge [
    {
      assertions = [
        (lib.hm.assertions.assertPlatform "programs.waybar" pkgs
          lib.platforms.linux)
      ];

      home.packages = [ cfg.package ];
    }

    (mkIf (cfg.settings != [ ]) {
      # Generate warnings about defined but unreferenced modules
      inherit warnings;

      xdg.configFile."waybar/config" = {
        source = configSource;
        onChange = ''
          ${pkgs.procps}/bin/pkill -u $USER -USR2 waybar || true
        '';
      };
    })

    (mkIf (cfg.style != null) {
      xdg.configFile."waybar/style.css" = {
        text = cfg.style;
        onChange = ''
          ${pkgs.procps}/bin/pkill -u $USER -USR2 waybar || true
        '';
      };
    })

    (mkIf cfg.systemd.enable {
      systemd.user.services.waybar = {
        Unit = {
          Description =
            "Highly customizable Wayland bar for Sway and Wlroots based compositors.";
          Documentation = "https://github.com/Alexays/Waybar/wiki";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${cfg.package}/bin/waybar";
          ExecReload = "kill -SIGUSR2 $MAINPID";
          Restart = "on-failure";
          KillMode = "mixed";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    })
  ]);
}
