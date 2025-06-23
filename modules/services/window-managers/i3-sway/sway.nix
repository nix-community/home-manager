{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mapAttrsToList
    mkIf
    mkOption
    optional
    types
    ;

  cfg = config.wayland.windowManager.sway;

  commonOptions = import ./lib/options.nix {
    inherit
      config
      lib
      cfg
      pkgs
      ;
    moduleName = "sway";
    capitalModuleName = "Sway";
  };

  configModule = types.submodule {
    options = {
      inherit (commonOptions)
        fonts
        window
        floating
        focus
        assigns
        workspaceLayout
        workspaceAutoBackAndForth
        modifier
        keycodebindings
        colors
        bars
        startup
        gaps
        menu
        terminal
        defaultWorkspace
        workspaceOutputAssign
        ;

      left = mkOption {
        type = types.str;
        default = "h";
        description = "Home row direction key for moving left.";
      };

      down = mkOption {
        type = types.str;
        default = "j";
        description = "Home row direction key for moving down.";
      };

      up = mkOption {
        type = types.str;
        default = "k";
        description = "Home row direction key for moving up.";
      };

      right = mkOption {
        type = types.str;
        default = "l";
        description = "Home row direction key for moving right.";
      };

      keybindings = mkOption {
        type = types.attrsOf (types.nullOr types.str);
        default = lib.mapAttrs (n: lib.mkOptionDefault) {
          "${cfg.config.modifier}+Return" = "exec ${cfg.config.terminal}";
          "${cfg.config.modifier}+Shift+q" = "kill";
          "${cfg.config.modifier}+d" = "exec ${cfg.config.menu}";

          "${cfg.config.modifier}+${cfg.config.left}" = "focus left";
          "${cfg.config.modifier}+${cfg.config.down}" = "focus down";
          "${cfg.config.modifier}+${cfg.config.up}" = "focus up";
          "${cfg.config.modifier}+${cfg.config.right}" = "focus right";

          "${cfg.config.modifier}+Left" = "focus left";
          "${cfg.config.modifier}+Down" = "focus down";
          "${cfg.config.modifier}+Up" = "focus up";
          "${cfg.config.modifier}+Right" = "focus right";

          "${cfg.config.modifier}+Shift+${cfg.config.left}" = "move left";
          "${cfg.config.modifier}+Shift+${cfg.config.down}" = "move down";
          "${cfg.config.modifier}+Shift+${cfg.config.up}" = "move up";
          "${cfg.config.modifier}+Shift+${cfg.config.right}" = "move right";

          "${cfg.config.modifier}+Shift+Left" = "move left";
          "${cfg.config.modifier}+Shift+Down" = "move down";
          "${cfg.config.modifier}+Shift+Up" = "move up";
          "${cfg.config.modifier}+Shift+Right" = "move right";

          "${cfg.config.modifier}+b" = "splith";
          "${cfg.config.modifier}+v" = "splitv";
          "${cfg.config.modifier}+f" = "fullscreen toggle";
          "${cfg.config.modifier}+a" = "focus parent";

          "${cfg.config.modifier}+s" = "layout stacking";
          "${cfg.config.modifier}+w" = "layout tabbed";
          "${cfg.config.modifier}+e" = "layout toggle split";

          "${cfg.config.modifier}+Shift+space" = "floating toggle";
          "${cfg.config.modifier}+space" = "focus mode_toggle";

          "${cfg.config.modifier}+1" = "workspace number 1";
          "${cfg.config.modifier}+2" = "workspace number 2";
          "${cfg.config.modifier}+3" = "workspace number 3";
          "${cfg.config.modifier}+4" = "workspace number 4";
          "${cfg.config.modifier}+5" = "workspace number 5";
          "${cfg.config.modifier}+6" = "workspace number 6";
          "${cfg.config.modifier}+7" = "workspace number 7";
          "${cfg.config.modifier}+8" = "workspace number 8";
          "${cfg.config.modifier}+9" = "workspace number 9";
          "${cfg.config.modifier}+0" = "workspace number 10";

          "${cfg.config.modifier}+Shift+1" = "move container to workspace number 1";
          "${cfg.config.modifier}+Shift+2" = "move container to workspace number 2";
          "${cfg.config.modifier}+Shift+3" = "move container to workspace number 3";
          "${cfg.config.modifier}+Shift+4" = "move container to workspace number 4";
          "${cfg.config.modifier}+Shift+5" = "move container to workspace number 5";
          "${cfg.config.modifier}+Shift+6" = "move container to workspace number 6";
          "${cfg.config.modifier}+Shift+7" = "move container to workspace number 7";
          "${cfg.config.modifier}+Shift+8" = "move container to workspace number 8";
          "${cfg.config.modifier}+Shift+9" = "move container to workspace number 9";
          "${cfg.config.modifier}+Shift+0" = "move container to workspace number 10";

          "${cfg.config.modifier}+Shift+minus" = "move scratchpad";
          "${cfg.config.modifier}+minus" = "scratchpad show";

          "${cfg.config.modifier}+Shift+c" = "reload";
          "${cfg.config.modifier}+Shift+e" =
            "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -b 'Yes, exit sway' 'swaymsg exit'";

          "${cfg.config.modifier}+r" = "mode resize";
        };
        defaultText = "Default sway keybindings.";
        description = ''
          An attribute set that assigns a key press to an action using a key symbol.
          See <https://i3wm.org/docs/userguide.html#keybindings>.

          Consider to use `lib.mkOptionDefault` function to extend or override
          default keybindings instead of specifying all of them from scratch.
        '';
        example = lib.literalExpression ''
          let
            modifier = config.wayland.windowManager.sway.config.modifier;
          in lib.mkOptionDefault {
            "''${modifier}+Return" = "exec ${cfg.config.terminal}";
            "''${modifier}+Shift+q" = "kill";
            "''${modifier}+d" = "exec ${cfg.config.menu}";
          }
        '';
      };

      bindswitches = mkOption {
        type = types.attrsOf bindswitchOption;
        default = { };
        defaultText = "No bindswitches by default";
        description = ''
          Binds <switch> to execute the sway command command on state changes. Supported switches are lid (laptop
          lid) and tablet (tablet mode) switches. Valid values for state are on, off and toggle. These switches are
          on when the device lid is shut and when tablet mode is active respectively. toggle is also supported to run
          a command both when the switch is toggled on or off.
          See sway(5).
        '';
        example = lib.literalExpression ''
          let
            laptop = "eDP-1";
          in
          {
            "lid:on" = {
              reload = true;
              locked = true;
              action = "output ''${laptop} disable";
            };
            "lid:off" = {
              reload = true;
              locked = true;
              action = "output ''${laptop} enable";
            };
          }
        '';
      };

      bindkeysToCode = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Whether to make use of {option}`--to-code` in keybindings.
        '';
      };

      input = mkOption {
        type = types.attrsOf (types.attrsOf types.str);
        default = { };
        example = {
          "*" = {
            xkb_variant = "dvorak";
          };
        };
        description = ''
          An attribute set that defines input modules. See
          {manpage}`sway-input(5)`
          for options.
        '';
      };

      output = mkOption {
        type = types.attrsOf (types.attrsOf types.str);
        default = { };
        example = {
          "HDMI-A-2" = {
            bg = "~/path/to/background.png fill";
          };
        };
        description = ''
          An attribute set that defines output modules. See
          {manpage}`sway-output(5)`
          for options.
        '';
      };

      seat = mkOption {
        type = types.attrsOf (types.attrsOf types.str);
        default = { };
        example = {
          "*" = {
            hide_cursor = "when-typing enable";
          };
        };
        description = ''
          An attribute set that defines seat modules. See
          {manpage}`sway-input(5)`
          for options.
        '';
      };

      modes = mkOption {
        type = types.attrsOf (types.attrsOf types.str);
        default = {
          resize = {
            "${cfg.config.left}" = "resize shrink width 10 px";
            "${cfg.config.down}" = "resize grow height 10 px";
            "${cfg.config.up}" = "resize shrink height 10 px";
            "${cfg.config.right}" = "resize grow width 10 px";
            "Left" = "resize shrink width 10 px";
            "Down" = "resize grow height 10 px";
            "Up" = "resize shrink height 10 px";
            "Right" = "resize grow width 10 px";
            "Escape" = "mode default";
            "Return" = "mode default";
          };
        };
        description = ''
          An attribute set that defines binding modes and keybindings
          inside them

          Only basic keybinding is supported (bindsym keycomb action),
          for more advanced setup use 'sway.extraConfig'.
        '';
      };
    };
  };

  wrapperOptions = types.submodule {
    options =
      let
        mkWrapperFeature =
          default: description:
          mkOption {
            type = types.bool;
            inherit default;
            example = !default;
            description = "Whether to make use of the ${description}";
          };
      in
      {
        base = mkWrapperFeature true ''
          base wrapper to execute extra session commands and prepend a
          dbus-run-session to the sway command.
        '';
        gtk = mkWrapperFeature false ''
          wrapGAppsHook wrapper to execute sway with required environment
          variables for GTK applications.
        '';
      };
  };

  bindswitchOption = types.submodule {
    options = {
      action = mkOption {
        type = types.str;
        description = "The sway command to execute on state changes";
      };

      locked = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Unless the flag --locked is set, the command
          will not be run when a screen locking program
          is active. If there is a matching binding with
          and without --locked, the one with will be preferred
          when locked and the one without will be
          preferred when unlocked.
        '';
      };

      reload = mkOption {
        type = types.bool;
        default = false;
        description = ''
          If the --reload flag is given, the binding will
          also be executed when the config is reloaded.
          toggle bindings will not be executed on reload.
          The --locked flag will operate as normal so if
          the config is reloaded while locked and
          --locked is not given, the binding will not be
          executed.
        '';
      };
    };
  };

  commonFunctions = import ./lib/functions.nix {
    inherit config cfg lib;
    moduleName = "sway";
  };

  inherit (commonFunctions)
    keybindingsStr
    keycodebindingsStr
    modeStr
    assignStr
    barStr
    gapsStr
    floatingCriteriaStr
    windowCommandsStr
    colorSetStr
    windowBorderString
    fontConfigStr
    keybindingDefaultWorkspace
    keybindingsRest
    workspaceOutputStr
    ;

  startupEntryStr =
    {
      command,
      always,
      ...
    }:
    ''
      ${if always then "exec_always" else "exec"} ${command}
    '';

  bindswitchesStr =
    bindswitches:
    concatStringsSep "\n" (
      mapAttrsToList (
        event:
        {
          locked,
          reload,
          action,
        }:
        let
          args = (lib.optionalString locked "--locked ") + (lib.optionalString reload "--reload ");
        in
        "bindswitch ${args} ${event} ${action}"
      ) bindswitches
    );

  moduleStr = moduleType: name: attrs: ''
    ${moduleType} "${name}" {
    ${concatStringsSep "\n" (lib.mapAttrsToList (name: value: "  ${name} ${value}") attrs)}
    }
  '';
  inputStr = moduleStr "input";
  outputStr = moduleStr "output";
  seatStr = moduleStr "seat";

  variables = concatStringsSep " " cfg.systemd.variables;
  extraCommands = concatStringsSep " && " cfg.systemd.extraCommands;
  systemdActivation = ''exec "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd ${variables}; ${extraCommands}"'';

  configFile = pkgs.writeTextFile {
    name = "sway.conf";

    # Sway always does some init, see https://github.com/swaywm/sway/issues/4691
    checkPhase = lib.optionalString cfg.checkConfig ''
      export DBUS_SESSION_BUS_ADDRESS=/dev/null
      export XDG_RUNTIME_DIR=$(mktemp -d)
      ${pkgs.xvfb-run}/bin/xvfb-run ${cfg.package}/bin/sway --config "$target" --validate --unsupported-gpu
    '';

    text =
      let
        # include and set should be at the top of the configuration
        setSettings = lib.filterAttrs (key: _: key == "set") cfg.settings;
        includeSettings = lib.filterAttrs (key: _: key == "include") cfg.settings;
        otherSettings = lib.filterAttrs (key: _: key != "set" && key != "include") cfg.settings;
      in
      lib.optionalString (setSettings != { }) (lib.hm.generators.toSwayConf { } setSettings)
      + lib.optionalString (includeSettings != { }) (lib.hm.generators.toSwayConf { } includeSettings)
      + lib.optionalString (otherSettings != { }) (lib.hm.generators.toSwayConf { } otherSettings)
      + concatStringsSep "\n" (
        (optional (cfg.extraConfigEarly != "") cfg.extraConfigEarly)
        ++ (
          if cfg.config != null then
            with cfg.config;
            (
              [
                (fontConfigStr fonts)
                "floating_modifier ${floating.modifier}"
                (windowBorderString window floating)
                "hide_edge_borders ${window.hideEdgeBorders}"
                "focus_wrapping ${focus.wrapping}"
                "focus_follows_mouse ${focus.followMouse}"
                "focus_on_window_activation ${focus.newWindow}"
                "mouse_warping ${
                  if builtins.isString (focus.mouseWarping) then
                    focus.mouseWarping
                  else if focus.mouseWarping then
                    "output"
                  else
                    "none"
                }"
                "workspace_layout ${workspaceLayout}"
                "workspace_auto_back_and_forth ${lib.hm.booleans.yesNo workspaceAutoBackAndForth}"
                "client.focused ${colorSetStr colors.focused}"
                "client.focused_inactive ${colorSetStr colors.focusedInactive}"
                "client.unfocused ${colorSetStr colors.unfocused}"
                "client.urgent ${colorSetStr colors.urgent}"
                "client.placeholder ${colorSetStr colors.placeholder}"
                "client.background ${colors.background}"
                (keybindingsStr {
                  keybindings = keybindingDefaultWorkspace;
                  bindsymArgs = lib.optionalString (cfg.config.bindkeysToCode) "--to-code";
                })
                (keybindingsStr {
                  keybindings = keybindingsRest;
                  bindsymArgs = lib.optionalString (cfg.config.bindkeysToCode) "--to-code";
                })
                (keycodebindingsStr keycodebindings)
              ]
              ++ optional (builtins.attrNames bindswitches != [ ]) (bindswitchesStr bindswitches)
              ++ mapAttrsToList inputStr input
              ++ mapAttrsToList outputStr output # outputs
              ++ mapAttrsToList seatStr seat # seats
              ++ mapAttrsToList (modeStr cfg.config.bindkeysToCode) modes # modes
              ++ mapAttrsToList assignStr assigns # assigns
              ++ map barStr bars # bars
              ++ optional (gaps != null) gapsStr # gaps
              ++ map floatingCriteriaStr floating.criteria # floating
              ++ map windowCommandsStr window.commands # window commands
              ++ map startupEntryStr startup # startup
              ++ map workspaceOutputStr workspaceOutputAssign # custom mapping
            )
          else
            [ ]
        )
        ++ (optional cfg.systemd.enable systemdActivation)
        ++ (optional (!cfg.xwayland) "xwayland disable")
        ++ [ cfg.extraConfig ]
      );
  };
in
{
  meta.maintainers = with lib.maintainers; [
    Scrumplex
    alexarice
    sumnerevans
    oxalica
    sinanmohd
  ];

  imports =
    let
      modulePath = [
        "wayland"
        "windowManager"
        "sway"
      ];
    in
    [
      (lib.mkRenamedOptionModule (modulePath ++ [ "systemdIntegration" ]) (
        modulePath
        ++ [
          "systemd"
          "enable"
        ]
      ))
    ];

  options.wayland.windowManager.sway = {
    enable = lib.mkEnableOption "sway wayland compositor";

    package = mkOption {
      type = with types; nullOr package;
      default = pkgs.sway.override {
        extraSessionCommands = cfg.extraSessionCommands;
        extraOptions = cfg.extraOptions;
        withBaseWrapper = cfg.wrapperFeatures.base;
        withGtkWrapper = cfg.wrapperFeatures.gtk;
      };
      defaultText = lib.literalExpression "${pkgs.sway}";
      description = ''
        Sway package to use. Will override the options
        'wrapperFeatures', 'extraSessionCommands', and 'extraOptions'.
        Set to `null` to not add any Sway package to your
        path. This should be done if you want to use the NixOS Sway
        module to install Sway. Beware setting to `null` will also disable
        reloading Sway when new config is activated.
      '';
    };

    systemd = {
      enable = mkOption {
        type = types.bool;
        default = pkgs.stdenv.isLinux;
        example = false;
        description = ''
          Whether to enable {file}`sway-session.target` on
          sway startup. This links to
          {file}`graphical-session.target`.
          Some important environment variables will be imported to systemd
          and dbus user environment before reaching the target, including
          * {env}`DISPLAY`
          * {env}`WAYLAND_DISPLAY`
          * {env}`SWAYSOCK`
          * {env}`XDG_CURRENT_DESKTOP`
          * {env}`XDG_SESSION_TYPE`
          * {env}`NIXOS_OZONE_WL`
          * {env}`XCURSOR_THEME`
          * {env}`XCURSOR_SIZE`
          You can extend this list using the `systemd.variables` option.
        '';
      };

      variables = mkOption {
        type = types.listOf types.str;
        default = [
          "DISPLAY"
          "WAYLAND_DISPLAY"
          "SWAYSOCK"
          "XDG_CURRENT_DESKTOP"
          "XDG_SESSION_TYPE"
          "NIXOS_OZONE_WL"
          "XCURSOR_THEME"
          "XCURSOR_SIZE"
        ];
        example = [ "--all" ];
        description = ''
          Environment variables imported into the systemd and D-Bus user environment.
        '';
      };

      extraCommands = mkOption {
        type = types.listOf types.str;
        default = [
          "systemctl --user reset-failed"
          "systemctl --user start sway-session.target"
          "swaymsg -mt subscribe '[]' || true"
          "systemctl --user stop sway-session.target"
        ];
        description = ''
          Extra commands to run after D-Bus activation.
        '';
      };

      xdgAutostart = lib.mkEnableOption ''
        autostart of applications using
        {manpage}`systemd-xdg-autostart-generator(8)`
      '';
    };

    xwayland = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable xwayland, which is needed for the default configuration of sway.
      '';
    };

    wrapperFeatures = mkOption {
      type = wrapperOptions;
      default = { };
      example = {
        gtk = true;
      };
      description = ''
        Attribute set of features to enable in the wrapper.
      '';
    };

    extraSessionCommands = mkOption {
      type = types.lines;
      default = "";
      example = ''
        export SDL_VIDEODRIVER=wayland
        # needs qt5.qtwayland in systemPackages
        export QT_QPA_PLATFORM=wayland
        export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
        # Fix for some Java AWT applications (e.g. Android Studio),
        # use this if they aren't displayed properly:
        export _JAVA_AWT_WM_NONREPARENTING=1
      '';
      description = ''
        Shell commands executed just before Sway is started.
      '';
    };

    extraOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "--verbose"
        "--debug"
        "--unsupported-gpu"
        "--my-next-gpu-wont-be-nvidia"
      ];
      description = ''
        Command line arguments passed to launch Sway. Please DO NOT report
        issues if you use an unsupported GPU (proprietary drivers).
      '';
    };

    settings = lib.mkOption {
      type =
        with lib.types;
        let
          valueType =
            oneOf [
              int
              float
              str
              path
              (listOf str)
              (attrsOf valueType)
            ]
            // {
              description = "Sway configuration value";
            };
        in
        valueType;
      default = { };
      description = ''
        Configuration for `sway`. See `sway(5)` for supported values.
      '';
    };

    config = mkOption {
      type = types.nullOr configModule;
      default = { };
      description = "Sway configuration options.";
    };

    checkConfig = mkOption {
      type = types.bool;
      default = cfg.package != null;
      defaultText = lib.literalExpression "wayland.windowManager.sway.package != null";
      description = "If enabled, validates the generated config file.";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra configuration lines to add to ~/.config/sway/config.";
    };

    extraConfigEarly = mkOption {
      type = types.lines;
      default = "";
      description = "Like extraConfig, except lines are added to ~/.config/sway/config before all other configuration.";
    };
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      (mkIf (cfg.config != null) {
        warnings =
          (optional (lib.isList cfg.config.fonts) "Specifying sway.config.fonts as a list is deprecated. Use the attrset version instead.")
          ++ lib.flatten (
            map (
              b:
              optional (lib.isList b.fonts) "Specifying sway.config.bars[].fonts as a list is deprecated. Use the attrset version instead."
            ) cfg.config.bars
          )
          ++ [
            (mkIf cfg.config.focus.forceWrapping "sway.config.focus.forceWrapping is deprecated, use focus.wrapping instead.")
          ];
      })

      {
        assertions = [
          (lib.hm.assertions.assertPlatform "wayland.windowManager.sway" pkgs lib.platforms.linux)
          {
            assertion = cfg.checkConfig -> cfg.package != null;
            message = "programs.sway.checkConfig requires non-null programs.sway.package";
          }
          {
            assertion = cfg.settings != { } -> cfg.extraConfigEarly == "";
            message = ''
              `wayland.windowManager.sway.extraConfigEarly` is not needed when
              using `wayland.windowManager.sway.settings`, it'll properly handle
              `set` and `include` configuration.
            '';
          }
        ];

        home.packages = optional (cfg.package != null) cfg.package ++ optional cfg.xwayland pkgs.xwayland;

        xdg.configFile."sway/config" = {
          source = configFile;
          onChange = lib.optionalString (cfg.package != null) ''
            swaySocket="''${XDG_RUNTIME_DIR:-/run/user/$UID}/sway-ipc.$UID.$(${pkgs.procps}/bin/pgrep --uid $UID -x sway || true).sock"
            if [ -S "$swaySocket" ]; then
              ${cfg.package}/bin/swaymsg -s $swaySocket reload
            fi
          '';
        };

        systemd.user.targets.sway-session = mkIf cfg.systemd.enable {
          Unit = {
            Description = "sway compositor session";
            Documentation = [ "man:systemd.special(7)" ];
            BindsTo = [ "graphical-session.target" ];
            Wants = [
              "graphical-session-pre.target"
            ] ++ optional cfg.systemd.xdgAutostart "xdg-desktop-autostart.target";
            After = [ "graphical-session-pre.target" ];
            Before = optional cfg.systemd.xdgAutostart "xdg-desktop-autostart.target";
          };
        };
      }
    ]
  );
}
