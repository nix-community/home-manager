{ config, options, lib, pkgs, ... }:

let
  inherit (builtins) elemAt isAttrs isBool length mapAttrs toJSON;
  inherit (lib)
    boolToString concatMapStringsSep concatStringsSep escape literalExpression
    mapAttrsToList mkEnableOption mkRenamedOptionModule mkRemovedOptionModule
    mkDefault mkIf mkOption optional types warn;

  cfg = config.services.picom;
  opt = options.services.picom;

  pairOf = x:
    with types;
    addCheck (listOf x) (y: length y == 2) // {
      description = "pair of ${x.description}";
    };

  mkDefaultAttrs = mapAttrs (n: v: mkDefault v);

  # Basically a tinkered lib.generators.mkKeyValueDefault
  # It either serializes a top-level definition "key: { values };"
  # or an expression "key = { values };"
  mkAttrsString = top:
    mapAttrsToList (k: v:
      let sep = if (top && isAttrs v) then ": " else " = ";
      in "${escape [ sep ] k}${sep}${mkValueString v};");

  # This serializes a Nix expression to the libconfig format.
  mkValueString = v:
    if types.bool.check v then
      boolToString v
    else if types.int.check v then
      toString v
    else if types.float.check v then
      toString v
    else if types.str.check v then
      ''"${escape [ ''"'' ] v}"''
    else if builtins.isList v then
      "[ ${concatMapStringsSep " , " mkValueString v} ]"
    else if types.attrs.check v then
      "{ ${concatStringsSep " " (mkAttrsString false v)} }"
    else
      throw ''
        invalid expression used in option services.picom.settings:
        ${v}
      '';

  toConf = attrs: concatStringsSep "\n" (mkAttrsString true cfg.settings);

  configFile = toConf cfg.settings;

in {
  imports = [
    (mkRemovedOptionModule [ "services" "picom" "refreshRate" ]
      "The option `refresh-rate` has been deprecated by upstream.")
    (mkRemovedOptionModule [ "services" "picom" "experimentalBackends" ]
      "The option `--experimental-backends` has been removed by upstream.")
    (mkRemovedOptionModule [ "services" "picom" "extraOptions" ]
      "This option has been replaced by `services.picom.settings`.")
    (mkRenamedOptionModule [ "services" "picom" "opacityRule" ] [
      "services"
      "picom"
      "opacityRules"
    ])
  ];

  options.services.picom = {
    enable = mkEnableOption "Picom X11 compositor";

    fade = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Fade windows in and out.
      '';
    };

    fadeDelta = mkOption {
      type = types.ints.positive;
      default = 10;
      example = 5;
      description = ''
        Time between fade animation step (in ms).
      '';
    };

    fadeSteps = mkOption {
      type = pairOf (types.numbers.between 1.0e-2 1);
      default = [ 2.8e-2 3.0e-2 ];
      example = [ 4.0e-2 4.0e-2 ];
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
        See <literal>picom(1)</literal> man page for more examples.
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
      type = pairOf types.int;
      default = [ (-15) (-15) ];
      example = [ (-10) (-15) ];
      description = ''
        Left and right offset for shadows (in pixels).
      '';
    };

    shadowOpacity = mkOption {
      type = types.numbers.between 0 1;
      default = 0.75;
      example = 0.8;
      description = ''
        Window shadows opacity.
      '';
    };

    shadowExclude = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "window_type *= 'menu'" "name ~= 'Firefox$'" "focused = 1" ];
      description = ''
        List of conditions of windows that should have no shadow.
        See <literal>picom(1)</literal> man page for more examples.
      '';
    };

    activeOpacity = mkOption {
      type = types.numbers.between 0 1;
      default = 1.0;
      example = 0.8;
      description = ''
        Opacity of active windows.
      '';
    };

    inactiveOpacity = mkOption {
      type = types.numbers.between 0.1 1;
      default = 1.0;
      example = 0.8;
      description = ''
        Opacity of inactive windows.
      '';
    };

    menuOpacity = mkOption {
      type = types.numbers.between 0 1;
      default = 1.0;
      example = 0.8;
      description = ''
        Opacity of dropdown and popup menu.
      '';
    };

    wintypes = mkOption {
      type = types.attrs;
      default = {
        popup_menu = { opacity = cfg.menuOpacity; };
        dropdown_menu = { opacity = cfg.menuOpacity; };
      };
      defaultText = literalExpression ''
        {
          popup_menu = { opacity = config.${opt.menuOpacity}; };
          dropdown_menu = { opacity = config.${opt.menuOpacity}; };
        }
      '';
      example = { };
      description = ''
        Rules for specific window types.
      '';
    };

    opacityRules = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "95:class_g = 'URxvt' && !_NET_WM_STATE@:32a"
        "0:_NET_WM_STATE@:32a *= '_NET_WM_STATE_HIDDEN'"
      ];
      description = ''
        Rules that control the opacity of windows, in format PERCENT:PATTERN.
      '';
    };

    backend = mkOption {
      type = types.enum [ "egl" "glx" "xrender" "xr_glx_hybrid" ];
      default = "xrender";
      description = ''
        Backend to use: <literal>egl</literal>, <literal>glx</literal>, <literal>xrender</literal> or <literal>xr_glx_hybrid</literal>.
      '';
    };

    vSync = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable vertical synchronization.
      '';
    };

    extraArgs = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = literalExpression ''[ "--legacy-backends" ]'';
      description = ''
        Extra arguments to be passed to the picom executable.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.picom;
      defaultText = literalExpression "pkgs.picom";
      example = literalExpression "pkgs.picom";
      description = ''
        Picom derivation to use.
      '';
    };

    settings = with types;
      let
        scalar = oneOf [ bool int float str ] // {
          description = "scalar types";
        };

        libConfig = oneOf [ scalar (listOf libConfig) (attrsOf libConfig) ] // {
          description = "libconfig type";
        };

        topLevel = attrsOf libConfig // {
          description = ''
            libconfig configuration. The format consists of an attributes
            set (called a group) of settings. Each setting can be a scalar type
            (boolean, integer, floating point number or string), a list of
            scalars or a group itself
          '';
        };

      in mkOption {
        type = topLevel;
        default = { };
        example = literalExpression ''
          blur =
            { method = "gaussian";
              size = 10;
              deviation = 5.0;
            };
        '';
        description = ''
          Picom settings. Use this option to configure Picom settings not exposed
          in a NixOS option or to bypass one. For the available options see the
          CONFIGURATION FILES section at <literal>picom(1)</literal>.
        '';
      };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.picom" pkgs
        lib.platforms.linux)
    ];

    services.picom.settings = mkDefaultAttrs {
      # fading
      fading = cfg.fade;
      fade-delta = cfg.fadeDelta;
      fade-in-step = elemAt cfg.fadeSteps 0;
      fade-out-step = elemAt cfg.fadeSteps 1;
      fade-exclude = cfg.fadeExclude;

      # shadows
      shadow = cfg.shadow;
      shadow-offset-x = elemAt cfg.shadowOffsets 0;
      shadow-offset-y = elemAt cfg.shadowOffsets 1;
      shadow-opacity = cfg.shadowOpacity;
      shadow-exclude = cfg.shadowExclude;

      # opacity
      active-opacity = cfg.activeOpacity;
      inactive-opacity = cfg.inactiveOpacity;

      wintypes = cfg.wintypes;

      opacity-rule = cfg.opacityRules;

      # other options
      backend = cfg.backend;
      vsync = cfg.vSync;
    };

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
        ] ++ cfg.extraArgs);
        Restart = "always";
        RestartSec = 3;
      };
    };
  };

  meta.maintainers = with lib.maintainers; [ thiagokokada ];
}
