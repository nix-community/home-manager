{ config, lib, pkgs, ... }:

let
  inherit (builtins) toJSON toString;
  inherit (lib)
    concatStringsSep elemAt literalExpression mkEnableOption mkIf mkOption
    mkRemovedOptionModule optional optionalAttrs optionalString types;

  cfg = config.services.picom;

  configFile = optionalString cfg.fade ''
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

    wintypes:
    {
      dock          = { shadow = ${toJSON (!cfg.noDockShadow)}; };
      dnd           = { shadow = ${toJSON (!cfg.noDNDShadow)}; };
      popup_menu    = { opacity = ${cfg.menuOpacity}; };
      dropdown_menu = { opacity = ${cfg.menuOpacity}; };
      ${cfg.extraWintypes}
    };

    # other options
    backend = ${toJSON cfg.backend};
    vsync = ${toJSON cfg.vSync};
  '' + cfg.extraOptions;

in {
  meta.maintainers = with maintainers; [ khushraj ];

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

    package = mkOption {
      type = types.package;
      default = pkgs.picom;
      defaultText = literalExpression "pkgs.picom";
      example = literalExpression "pkgs.picom";
      description = ''
        picom derivation to use.
      '';
    };

    extraWintypes = mkOption {
      type = types.str;
      default = "";
      example = literalExample ''
        tooltip = {
          fade = true;
          shadow = true;
        };
        dock = { opacity = 0.75; };
      '';
      description = ''
        Additional wintypes.
      '';
    };

    extraOptions = mkOption {
      type = types.lines;
      default = "";
      example = literalExample ''
        unredir-if-possible = true;
        dbe = true;
      '';
      description = ''
        Additional Picom configuration.
      '';
    };
  };

  imports = [
    (mkRemovedOptionModule [ "services" "picom" "refreshRate" ]
      "The option `refresh-rate` has been deprecated by upstream.")
  ];

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.picom" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."picom/picom.conf".text = configFile;

    systemd.user.services.picom = {
      Unit = {
        Description = "Picom X11 compositor";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        ExecStart = concatStringsSep " " ([
          "${cfg.package}/bin/picom"
          "--config ${config.xdg.configFile."picom/picom.conf".source}"
        ] ++ optional cfg.experimentalBackends "--experimental-backends");
        Restart = "always";
        RestartSec = 3;
      };
    };
  };
}
