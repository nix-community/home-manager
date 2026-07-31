{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.wayland.windowManager.niri;
in
{
  meta.maintainers = with lib.maintainers; [
    lukasngl
    glmlm
  ];

  options.wayland.windowManager.niri = {
    enable = lib.mkEnableOption "niri";

    package = lib.mkPackageOption pkgs "niri" {
      nullable = true;
      extraDescription = ''
        Set to `null` to not add any niri package to your path.
      '';
    };

    systemd = {
      enable = lib.mkEnableOption "systemd" // {
        default = true;
        description = ''
          Whether to install niri's systemd units from the {option}`package`,
          that are used by {command}`niri-session`.
        '';
      };

      # Note: this option is expected to be present by way-display.
      variables = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Environment variables to be imported in the systemd & D-Bus user
          environment. Not used by niri, as {command}`niri-session` already
          imports all environment variables.
        '';
      };
    };

    xwaylandSatellitePackage = lib.mkPackageOption pkgs "xwayland-satellite" {
      nullable = true;
      extraDescription = ''
        With `xwayland-satellite` in the {env}`$PATH`, niri can automatically
        start XWayland when needed. Set to `null` if you want to disable xwayland.
        See <https://yalter.github.io/niri/Xwayland.html>.
      '';
    };

    portalPackage = lib.mkPackageOption pkgs "xdg-desktop-portal-gnome" {
      nullable = true;
      extraDescription = ''
        The portal implementation to use with niri. Niri ships a portal
        configuration that prefers `gnome` and `gtk` portals.
        Set to `null` to not install any portal package.
      '';
    };

    checkConfig = lib.mkOption {
      type = lib.types.bool;
      default = cfg.package != null;
      defaultText = lib.literalExpression "wayland.windowManager.niri.package != null";
      description = "If enabled and package is not null, validates the generated config file.";
    };

    settings = lib.mkOption {
      type =
        with lib.types;
        let
          valueType =
            nullOr (oneOf [
              bool
              int
              float
              str
              (attrsOf valueType)
              (listOf valueType)
            ])
            // {
              description = "KDL value";
            };
        in
        attrsOf valueType;
      default = { };
      example = lib.literalExpression ''
        {
          # str/num/bool → single argument
          screenshot-path = "~/Screenshots/%Y-%m-%d %H-%M-%S.png";
          layout.gaps = 8;
          layout.shadow.draw-behind-window = true;

          # {} → leaf node
          prefer-no-csd = {};
          input.touchpad.tap = {};

          # _props → named properties: offset x=0 y=5
          layout.shadow.offset._props = { x = 0; y = 5; };

          # _children → ordered/repeated children
          layout.preset-column-widths._children = [
            { proportion = 0.33333; }
            { proportion = 0.5; }
          ];

          # _props + list args in binds
          binds = {
            "Mod+H".focus-column-left = {};
            "Mod+Return" = {
              _props.hotkey-overlay-title = "Open a Terminal";
              spawn = ["ghostty"];
            };
            "XF86AudioRaiseVolume" = {
              _props.allow-when-locked = true;
              spawn = ["wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"];
            };
          };

          # _args for repeated/parameterized top-level nodes
          _children = [
            { workspace._args = ["chat"]; }
            { workspace._args = ["dev"]; }
            # _args + children
            { output = { _args = ["eDP-1"]; scale = 2.0; }; }
            # nested _children + _props
            {
              window-rule._children = [
                { match._props = { app-id = "firefox"; at-startup = true; }; }
                { open-on-workspace = "dev"; }
              ];
            }
          ];
        }
      '';
      description = ''
        Configuration added to {file}`$XDG_CONFIG_HOME/niri/config.kdl`.
        See <https://yalter.github.io/niri/Configuration%3A-Introduction.html> for the full list of options.
      '';
    };

    extraConfigEarly = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra configuration lines added to {file}`$XDG_CONFIG_HOME/niri/config.kdl` before config generated from the options.";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra configuration lines added to {file}`$XDG_CONFIG_HOME/niri/config.kdl` after the config generated from the options.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "wayland.windowManager.niri" pkgs lib.platforms.linux)
      {
        assertion = cfg.systemd.enable -> cfg.package != null;
        message = "wayland.windowManager.niri.systemd.enable requires a non-null package";
      }
      {
        assertion = cfg.checkConfig -> cfg.package != null;
        message = "wayland.windowManager.niri.checkConfig requires a non-null package";
      }
    ];

    home.packages = lib.concatLists [
      (lib.optional (cfg.package != null) cfg.package)
      (lib.optional (cfg.xwaylandSatellitePackage != null) cfg.xwaylandSatellitePackage)
    ];

    systemd.user.packages = lib.optional cfg.systemd.enable cfg.package;

    xdg.portal = lib.mkIf (cfg.portalPackage != null) {
      enable = true;
      extraPortals = [ cfg.portalPackage ];
      configPackages = lib.optional (cfg.package != null) cfg.package;
    };

    xdg.configFile."niri/config.kdl" =
      let
        toKDL = lib.hm.generators.toKDL {
          escapeBackslashes = true;
          escapeTabs = true;
        };
        defaultSettings = {
          binds = {
            "Mod+Shift+Slash" = {
              show-hotkey-overlay = { };
            };
            "Mod+T" = {
              _props.hotkey-overlay-title = "Open a Terminal: alacritty";
              spawn = [ "alacritty" ];
            };
            "Mod+D" = {
              _props.hotkey-overlay-title = "Run an Application: fuzzel";
              spawn = [ "fuzzel" ];
            };
            "Super+Alt+L" = {
              _props.hotkey-overlay-title = "Lock the Screen: swaylock";
              spawn = [ "swaylock" ];
            };
            "Super+Alt+S" = {
              _props.allow-when-locked = true;
              _props.hotkey-overlay-title = null;
              spawn-sh = [ "pkill orca || exec orca" ];
            };
            "XF86AudioRaiseVolume" = {
              _props.allow-when-locked = true;
              spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0";
            };
            "XF86AudioLowerVolume" = {
              _props.allow-when-locked = true;
              spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
            };
            "XF86AudioMute" = {
              _props.allow-when-locked = true;
              spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            };
            "XF86AudioMicMute" = {
              _props.allow-when-locked = true;
              spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
            };
            "XF86AudioPlay" = {
              _props.allow-when-locked = true;
              spawn-sh = "playerctl play-pause";
            };
            "XF86AudioStop" = {
              _props.allow-when-locked = true;
              spawn-sh = "playerctl stop";
            };
            "XF86AudioPrev" = {
              _props.allow-when-locked = true;
              spawn-sh = "playerctl previous";
            };
            "XF86AudioNext" = {
              _props.allow-when-locked = true;
              spawn-sh = "playerctl next";
            };
            "XF86MonBrightnessUp" = {
              _props.allow-when-locked = true;
              spawn = [
                "brightnessctl"
                "--class=backlight"
                "set"
                "+10%"
              ];
            };
            "XF86MonBrightnessDown" = {
              _props.allow-when-locked = true;
              spawn = [
                "brightnessctl"
                "--class=backlight"
                "set"
                "10%-"
              ];
            };
            "Mod+O" = {
              _props.repeat = false;
              toggle-overview = { };
            };
            "Mod+Q" = {
              _props.repeat = false;
              close-window = { };
            };
            "Mod+Left" = {
              focus-column-left = { };
            };
            "Mod+Down" = {
              focus-window-down = { };
            };
            "Mod+Up" = {
              focus-window-up = { };
            };
            "Mod+Right" = {
              focus-column-right = { };
            };
            "Mod+H" = {
              focus-column-left = { };
            };
            "Mod+J" = {
              focus-window-down = { };
            };
            "Mod+K" = {
              focus-window-up = { };
            };
            "Mod+L" = {
              focus-column-right = { };
            };
            "Mod+Ctrl+Left" = {
              move-column-left = { };
            };
            "Mod+Ctrl+Down" = {
              move-window-down = { };
            };
            "Mod+Ctrl+Up" = {
              move-window-up = { };
            };
            "Mod+Ctrl+Right" = {
              move-column-right = { };
            };
            "Mod+Ctrl+H" = {
              move-column-left = { };
            };
            "Mod+Ctrl+J" = {
              move-window-down = { };
            };
            "Mod+Ctrl+K" = {
              move-window-up = { };
            };
            "Mod+Ctrl+L" = {
              move-column-right = { };
            };
            "Mod+Home" = {
              focus-column-first = { };
            };
            "Mod+End" = {
              focus-column-last = { };
            };
            "Mod+Ctrl+Home" = {
              move-column-to-first = { };
            };
            "Mod+Ctrl+End" = {
              move-column-to-last = { };
            };
            "Mod+Shift+Left" = {
              focus-monitor-left = { };
            };
            "Mod+Shift+Down" = {
              focus-monitor-down = { };
            };
            "Mod+Shift+Up" = {
              focus-monitor-up = { };
            };
            "Mod+Shift+Right" = {
              focus-monitor-right = { };
            };
            "Mod+Shift+H" = {
              focus-monitor-left = { };
            };
            "Mod+Shift+J" = {
              focus-monitor-down = { };
            };
            "Mod+Shift+K" = {
              focus-monitor-up = { };
            };
            "Mod+Shift+L" = {
              focus-monitor-right = { };
            };
            "Mod+Shift+Ctrl+Left" = {
              move-column-to-monitor-left = { };
            };
            "Mod+Shift+Ctrl+Down" = {
              move-column-to-monitor-down = { };
            };
            "Mod+Shift+Ctrl+Up" = {
              move-column-to-monitor-up = { };
            };
            "Mod+Shift+Ctrl+Right" = {
              move-column-to-monitor-right = { };
            };
            "Mod+Shift+Ctrl+H" = {
              move-column-to-monitor-left = { };
            };
            "Mod+Shift+Ctrl+J" = {
              move-column-to-monitor-down = { };
            };
            "Mod+Shift+Ctrl+K" = {
              move-column-to-monitor-up = { };
            };
            "Mod+Shift+Ctrl+L" = {
              move-column-to-monitor-right = { };
            };
            "Mod+Page_Down" = {
              focus-workspace-down = { };
            };
            "Mod+Page_Up" = {
              focus-workspace-up = { };
            };
            "Mod+U" = {
              focus-workspace-down = { };
            };
            "Mod+I" = {
              focus-workspace-up = { };
            };
            "Mod+Ctrl+Page_Down" = {
              move-column-to-workspace-down = { };
            };
            "Mod+Ctrl+Page_Up" = {
              move-column-to-workspace-up = { };
            };
            "Mod+Ctrl+U" = {
              move-column-to-workspace-down = { };
            };
            "Mod+Ctrl+I" = {
              move-column-to-workspace-up = { };
            };
            "Mod+Shift+Page_Down" = {
              move-workspace-down = { };
            };
            "Mod+Shift+Page_Up" = {
              move-workspace-up = { };
            };
            "Mod+Shift+U" = {
              move-workspace-down = { };
            };
            "Mod+Shift+I" = {
              move-workspace-up = { };
            };
            "Mod+WheelScrollDown" = {
              _props.cooldown-ms = 150;
              focus-workspace-down = { };
            };
            "Mod+WheelScrollUp" = {
              _props.cooldown-ms = 150;
              focus-workspace-up = { };
            };
            "Mod+Ctrl+WheelScrollDown" = {
              _props.cooldown-ms = 150;
              move-column-to-workspace-down = { };
            };
            "Mod+Ctrl+WheelScrollUp" = {
              _props.cooldown-ms = 150;
              move-column-to-workspace-up = { };
            };
            "Mod+WheelScrollRight" = {
              focus-column-right = { };
            };
            "Mod+WheelScrollLeft" = {
              focus-column-left = { };
            };
            "Mod+Ctrl+WheelScrollRight" = {
              move-column-right = { };
            };
            "Mod+Ctrl+WheelScrollLeft" = {
              move-column-left = { };
            };
            "Mod+Shift+WheelScrollDown" = {
              focus-column-right = { };
            };
            "Mod+Shift+WheelScrollUp" = {
              focus-column-left = { };
            };
            "Mod+Ctrl+Shift+WheelScrollDown" = {
              move-column-right = { };
            };
            "Mod+Ctrl+Shift+WheelScrollUp" = {
              move-column-left = { };
            };
            "Mod+1" = {
              focus-workspace = 1;
            };
            "Mod+2" = {
              focus-workspace = 2;
            };
            "Mod+3" = {
              focus-workspace = 3;
            };
            "Mod+4" = {
              focus-workspace = 4;
            };
            "Mod+5" = {
              focus-workspace = 5;
            };
            "Mod+6" = {
              focus-workspace = 6;
            };
            "Mod+7" = {
              focus-workspace = 7;
            };
            "Mod+8" = {
              focus-workspace = 8;
            };
            "Mod+9" = {
              focus-workspace = 9;
            };
            "Mod+Ctrl+1" = {
              move-column-to-workspace = 1;
            };
            "Mod+Ctrl+2" = {
              move-column-to-workspace = 2;
            };
            "Mod+Ctrl+3" = {
              move-column-to-workspace = 3;
            };
            "Mod+Ctrl+4" = {
              move-column-to-workspace = 4;
            };
            "Mod+Ctrl+5" = {
              move-column-to-workspace = 5;
            };
            "Mod+Ctrl+6" = {
              move-column-to-workspace = 6;
            };
            "Mod+Ctrl+7" = {
              move-column-to-workspace = 7;
            };
            "Mod+Ctrl+8" = {
              move-column-to-workspace = 8;
            };
            "Mod+Ctrl+9" = {
              move-column-to-workspace = 9;
            };
            "Mod+BracketLeft" = {
              consume-or-expel-window-left = { };
            };
            "Mod+BracketRight" = {
              consume-or-expel-window-right = { };
            };
            "Mod+Comma" = {
              consume-window-into-column = { };
            };
            "Mod+Period" = {
              expel-window-from-column = { };
            };
            "Mod+R" = {
              switch-preset-column-width = { };
            };
            "Mod+Shift+R" = {
              switch-preset-column-width-back = { };
            };
            "Mod+Ctrl+Shift+R" = {
              switch-preset-window-height = { };
            };
            "Mod+Ctrl+R" = {
              reset-window-height = { };
            };
            "Mod+F" = {
              maximize-column = { };
            };
            "Mod+Shift+F" = {
              fullscreen-window = { };
            };
            "Mod+M" = {
              maximize-window-to-edges = { };
            };
            "Mod+Ctrl+F" = {
              expand-column-to-available-width = { };
            };
            "Mod+C" = {
              center-column = { };
            };
            "Mod+Ctrl+C" = {
              center-visible-columns = { };
            };
            "Mod+Minus" = {
              set-column-width = "-10%";
            };
            "Mod+Equal" = {
              set-column-width = "+10%";
            };
            "Mod+Shift+Minus" = {
              set-window-height = "-10%";
            };
            "Mod+Shift+Equal" = {
              set-window-height = "+10%";
            };
            "Mod+V" = {
              toggle-window-floating = { };
            };
            "Mod+Shift+V" = {
              switch-focus-between-floating-and-tiling = { };
            };
            "Mod+W" = {
              toggle-column-tabbed-display = { };
            };
            "Print" = {
              screenshot = { };
            };
            "Ctrl+Print" = {
              screenshot-screen = { };
            };
            "Alt+Print" = {
              screenshot-window = { };
            };
            "Mod+Escape" = {
              _props.allow-inhibiting = false;
              toggle-keyboard-shortcuts-inhibit = { };
            };
            "Mod+Shift+E" = {
              quit = { };
            };
            "Ctrl+Alt+Delete" = {
              quit = { };
            };
            "Mod+Shift+P" = {
              power-off-monitors = { };
            };
          };
        };
        settings = lib.trim (toKDL (lib.recursiveUpdate defaultSettings cfg.settings));
        configLines = lib.concatStringsSep "\n" (
          lib.filter (line: line != "") [
            cfg.extraConfigEarly
            settings
            cfg.extraConfig
          ]
        );
      in
      lib.mkIf (configLines != "") {
        source = pkgs.writeTextFile {
          name = "niri-config.kdl";
          text = ''
            // Automatically generated by home-manager from `wayland.windowManager.niri`
            ${configLines}
          '';
          checkPhase = lib.optionalString cfg.checkConfig ''
            ${lib.getExe cfg.package} validate --config "$target"
          '';
        };
      };

  };
}
