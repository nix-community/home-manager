{ config, lib, pkgs, ... }:

with lib;
with builtins;

let

  cfg = config.services.picom;

  configFile = pkgs.writeText "picom.conf" (optionalString cfg.fade ''
    # fading
    fading = true;
    fade-delta    = ${toString cfg.fadeDelta};
    fade-in-step  = ${elemAt cfg.fadeSteps 0};
    fade-out-step = ${elemAt cfg.fadeSteps 1};
    fade-exclude  = ${toJSON cfg.fadeExclude};
  '' + optionalString cfg.shadow ''

    # shadows
    shadow = true;
    shadow-offset-x = ${toString (elemAt cfg.shadowOffsets 0)};
    shadow-offset-y = ${toString (elemAt cfg.shadowOffsets 1)};
    shadow-opacity  = ${cfg.shadowOpacity};
    shadow-exclude  = ${toJSON cfg.shadowExclude};
  '' + optionalString cfg.blur ''

    # blur
    blur-background         = true;
    blur-background-exclude = ${toJSON cfg.blurExclude};
  '' + ''

    # opacity
    active-opacity   = ${cfg.activeOpacity};
    inactive-opacity = ${cfg.inactiveOpacity};
    inactive-dim     = ${cfg.inactiveDim};
    opacity-rule     = ${toJSON cfg.opacityRule};
  '' + (let
    moduleToString = rules:
      with rules; ''
        {
          ${optionalString (fade != null) "fade = ${toJSON fade};"}
          ${optionalString (shadow != null) "shadow = ${toJSON shadow};"}
          ${optionalString (opacity != null) "opacity = ${opacity};"}
          ${optionalString (focus != null) "focus = ${toJSON focus};"}
          ${
            optionalString (fullShadow != null)
            "full-shadow = ${toJSON fullShadow};"
          }
          ${
            optionalString (redirIgnore != null)
            "redir-ignore = ${toJSON redirIgnore};"
          }
        }
      '';
  in ''

    wintypes:
    {
      unknown       = ${moduleToString cfg.windowType.unknown};
      desktop       = ${moduleToString cfg.windowType.desktop};
      dock          = ${moduleToString cfg.windowType.dock};
      toolbar       = ${moduleToString cfg.windowType.toolbar};
      menu          = ${moduleToString cfg.windowType.menu};
      utility       = ${moduleToString cfg.windowType.utility};
      splash        = ${moduleToString cfg.windowType.splash};
      dialog        = ${moduleToString cfg.windowType.dialog};
      normal        = ${moduleToString cfg.windowType.normal};
      dropdown_menu = ${moduleToString cfg.windowType.dropdownMenu};
      popup_menu    = ${moduleToString cfg.windowType.popupMenu};
      tooltip       = ${moduleToString cfg.windowType.tooltip};
      notify        = ${moduleToString cfg.windowType.notify};
      combo         = ${moduleToString cfg.windowType.combo};
      dnd           = ${moduleToString cfg.windowType.dnd};
    };
  '') + ''

    # other options
    backend = ${toJSON cfg.backend};
    vsync = ${toJSON cfg.vSync};
    refresh-rate = ${toString cfg.refreshRate};
  '' + cfg.extraOptions);

in {

  options.services.picom = {
    enable = mkEnableOption "Picom X11 compositor";

    blur = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable background blur on transparent windows.
      '';
    };

    blurExclude = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "class_g = 'slop'" "class_i = 'polybar'" ];
      description = ''
        List of windows to exclude background blur.
        See the
        <citerefentry>
          <refentrytitle>picom</refentrytitle>
          <manvolnum>1</manvolnum>
        </citerefentry>
        man page for more examples.
      '';
    };

    experimentalBackends = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to use the new experimental backends.
      '';
    };

    fade = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Fade windows in and out.
      '';
    };

    fadeDelta = mkOption {
      type = types.int;
      default = 10;
      example = 5;
      description = ''
        Time between fade animation step (in ms).
      '';
    };

    fadeSteps = mkOption {
      type = types.listOf types.str;
      default = [ "0.028" "0.03" ];
      example = [ "0.04" "0.04" ];
      description = ''
        Opacity change between fade steps (in and out).
      '';
    };

    fadeExclude = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "window_type *= 'menu'" "name ~= 'Firefox$'" "focused = 1" ];
      description = ''
        List of conditions of windows that should not be faded.
        See the
        <citerefentry>
          <refentrytitle>picom</refentrytitle>
          <manvolnum>1</manvolnum>
        </citerefentry>
        man page for more examples.
      '';
    };

    shadow = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Draw window shadows.
      '';
    };

    shadowOffsets = mkOption {
      type = types.listOf types.int;
      default = [ (-15) (-15) ];
      example = [ (-10) (-15) ];
      description = ''
        Horizontal and vertical offsets for shadows (in pixels).
      '';
    };

    shadowOpacity = mkOption {
      type = types.str;
      default = "0.75";
      example = "0.8";
      description = ''
        Window shadows opacity (number in range 0 - 1).
      '';
    };

    shadowExclude = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "window_type *= 'menu'" "name ~= 'Firefox$'" "focused = 1" ];
      description = ''
        List of conditions of windows that should have no shadow.
        See the
        <citerefentry>
          <refentrytitle>picom</refentrytitle>
          <manvolnum>1</manvolnum>
        </citerefentry>
        man page for more examples.
      '';
    };

    noDockShadow = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Avoid shadow on docks.
      '';
    };

    noDNDShadow = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Avoid shadow on drag-and-drop windows.
      '';
    };

    activeOpacity = mkOption {
      type = types.str;
      default = "1.0";
      example = "0.8";
      description = ''
        Opacity of active windows.
      '';
    };

    inactiveDim = mkOption {
      type = types.str;
      default = "0.0";
      example = "0.2";
      description = ''
        Dim inactive windows.
      '';
    };

    inactiveOpacity = mkOption {
      type = types.str;
      default = "1.0";
      example = "0.8";
      description = ''
        Opacity of inactive windows.
      '';
    };

    menuOpacity = mkOption {
      type = types.str;
      default = "1.0";
      example = "0.8";
      description = ''
        Opacity of dropdown and popup menu.
      '';
    };

    opacityRule = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "87:class_i ?= 'scratchpad'" "91:class_i ?= 'xterm'" ];
      description = ''
        List of opacity rules.
        See the
        <citerefentry>
          <refentrytitle>picom</refentrytitle>
          <manvolnum>1</manvolnum>
        </citerefentry>
        man page for more examples.
      '';
    };

    backend = mkOption {
      type = types.str;
      default = "glx";
      description = ''
        Backend to use: <literal>glx</literal> or <literal>xrender</literal>.
      '';
    };

    vSync = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable vertical synchronization.
      '';
    };

    refreshRate = mkOption {
      type = types.int;
      default = 0;
      example = 60;
      description = ''
        Screen refresh rate (0 = automatically detect).
      '';
    };

    windowType = let
      rulesOption = mkOption {
        type = with types;
          submodule {
            options = {
              fade = mkOption {
                type = nullOr bool;
                default = null;
                description = "Whether to enable fading for this window type.";
              };

              shadow = mkOption {
                type = nullOr bool;
                default = null;
                description = "Whether to enable shadows for this window type";
              };

              opacity = mkOption {
                type = nullOr str;
                default = null;
                description = "Default opacity of the window type.";
              };

              focus = mkOption {
                type = nullOr bool;
                default = null;
                description = ''
                  Controls whether the window of this type is to be always
                  considered focused. (By default, all window types except
                  "normal" and "dialog" have this on.)
                '';
              };

              fullShadow = mkOption {
                type = nullOr bool;
                default = null;
                description = ''
                  Controls whether shadow is drawn under the parts of the window
                  that you normally won’t be able to see. Useful when the window
                  has parts of it transparent, and you want shadows in those areas.
                '';
              };

              redirIgnore = mkOption {
                type = nullOr bool;
                default = null;
                description = ''
                  Controls whether this type of windows should cause screen to
                  become redirected again after been unredirected. If you have
                  <literal>--unredir-if-possible</literal> set, and do not want
                  certain window to cause unnecessary screen redirection,
                  you can set this to true.
                '';
              };
            };
          };
        default = { };
        description = "Specific settings for this window type.";
      };
    in {
      unknown = rulesOption;
      desktop = rulesOption;
      dock = rulesOption;
      toolbar = rulesOption;
      menu = rulesOption;
      utility = rulesOption;
      splash = rulesOption;
      dialog = rulesOption;
      normal = rulesOption;
      dropdownMenu = rulesOption;
      popupMenu = rulesOption;
      tooltip = rulesOption;
      notify = rulesOption;
      combo = rulesOption;
      dnd = rulesOption;
    };

    package = mkOption {
      type = types.package;
      default = pkgs.picom;
      defaultText = literalExample "pkgs.picom";
      example = literalExample "pkgs.picom";
      description = ''
        picom derivation to use.
      '';
    };

    extraOptions = mkOption {
      type = types.str;
      default = "";
      example = ''
        unredir-if-possible = true;
        dbe = true;
      '';
      description = ''
        Additional Picom configuration.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    services.picom.windowType.popupMenu.opacity = mkDefault cfg.menuOpacity;
    services.picom.windowType.dropdownMenu.opacity = mkDefault cfg.menuOpacity;
    services.picom.windowType.dnd = mkIf cfg.noDNDShadow { shadow = false; };
    services.picom.windowType.dock = mkIf cfg.noDockShadow { shadow = false; };

    systemd.user.services.picom = {
      Unit = {
        Description = "Picom X11 compositor";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = let
        experimentalBackendsFlag =
          if cfg.experimentalBackends then " --experimental-backends" else "";
      in {
        ExecStart = "${cfg.package}/bin/picom --config ${configFile}"
          + experimentalBackendsFlag;
        Restart = "always";
        RestartSec = 3;
      } // optionalAttrs (cfg.backend == "glx") {
        # Temporarily fixes corrupt colours with Mesa 18.
        Environment = [ "allow_rgb10_configs=false" ];
      };
    };
  };
}
