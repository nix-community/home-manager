{ config, lib, pkgs, ... }:

let
  inherit (lib) types;
  cfg = config.wayland.windowManager.river;

  # Systemd integration
  variables = builtins.concatStringsSep " " cfg.systemd.variables;
  extraCommands = builtins.concatStringsSep " "
    (map (f: "&& ${f}") cfg.systemd.extraCommands);
  systemdActivation = ''
    ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd ${variables} ${extraCommands}
  '';

  toValue = val:
    if lib.isString val || lib.isDerivation val then
      toString val
    else if true == val then
      "enabled"
    else if false == val then
      "disabled"
    else if lib.isInt val then
      toString val
    else if lib.isFloat val then
      lib.strings.floatToString val
    else
      abort "unsupported type ${builtins.typeOf val}";

  # Intermediary function that converts some value (attrs, str, ...) to one or several commands.
  toArgs = path: value:

    let
      stringValue = lib.concatStringsSep " " (path ++ [ (toValue value) ]);
      finalValue = if lib.isAttrs value then
        toCommand path value
      else if lib.isList value then
        lib.lists.flatten (map (x: toArgs path x) value)
      else if value == null then
        [ ]
      else
        [ stringValue ];
    in finalValue;

  # toCommand :: [string] -> attrs -> [string]
  # Recursive function that converts an attrs to a list of commands that can be written to the
  # config file.
  toCommand = basePath: attrs:
    lib.concatLists (lib.mapAttrsToList
      (key: value: let path = basePath ++ [ key ]; in toArgs path value) attrs);

in {
  meta.maintainers = [ lib.maintainers.GaetanLepage ];

  options.wayland.windowManager.river = {
    enable = lib.mkEnableOption "the river window manager";

    package = lib.mkPackageOption pkgs "river" {
      nullable = true;
      extraDescription = ''
        Set to `null` to not add any river package to your path.
        This should be done if you want to use the NixOS river module to install river.
      '';
    };

    xwayland.enable = lib.mkEnableOption "XWayland" // { default = true; };

    systemd = {
      enable = lib.mkEnableOption null // {
        default = true;
        description = ''
          Whether to enable {file}`river-session.target` on
          river startup. This links to {file}`graphical-session.target`}.
          Some important environment variables will be imported to systemd
          and D-Bus user environment before reaching the target, including
          - `DISPLAY`
          - `WAYLAND_DISPLAY`
          - `XDG_CURRENT_DESKTOP`
          - `NIXOS_OZONE_WL`
          - `XCURSOR_THEME`
          - `XCURSOR_SIZE`
        '';
      };

      variables = lib.mkOption {
        type = types.listOf types.str;
        default = [
          "DISPLAY"
          "WAYLAND_DISPLAY"
          "XDG_CURRENT_DESKTOP"
          "NIXOS_OZONE_WL"
          "XCURSOR_THEME"
          "XCURSOR_SIZE"
        ];
        example = [ "-all" ];
        description = ''
          Environment variables to be imported in the systemd & D-Bus user
          environment.
        '';
      };

      extraCommands = lib.mkOption {
        type = types.listOf types.str;
        default = [
          "systemctl --user stop river-session.target"
          "systemctl --user start river-session.target"
        ];
        description = "Extra commands to be run after D-Bus activation.";
      };
    };

    extraSessionVariables = lib.mkOption {
      type = types.attrs;
      default = { };
      description = "Extra session variables set when running the compositor.";
      example = { MOZ_ENABLE_WAYLAND = "1"; };
    };

    settings = lib.mkOption {
      type = let
        valueType = with types;
          nullOr (oneOf [
            bool
            int
            float
            str
            path
            (attrsOf valueType)
            (listOf valueType)
          ]) // {
            description = "River configuration value";
          };
      in valueType;
      default = { };
      description = "General settings given to `riverctl`.";
      example = {
        border-width = 2;
        declare-mode = [ "locked" "normal" "passthrough" ];
        map.normal."Alt Q" = "close";
        input.pointer-foo-bar = {
          accel-profile = "flat";
          events = true;
          pointer-accel = -0.3;
          tap = false;
        };
        rule-add."-app-id" = {
          "'bar'" = "csd";
          "'float*'"."-title"."'foo'" = "float";
        };
        set-cursor-warp = "on-output-change";
        set-repeat = "50 300";
        xcursor-theme = "someGreatTheme 12";
        spawn = [ "firefox" "'foot -a terminal'" ];
      };
    };

    extraConfig = lib.mkOption {
      type = types.lines;
      default = "";
      example = ''
        rivertile -view-padding 6 -outer-padding 6 &
      '';
      description =
        "Extra lines appended to {file}`$XDG_CONFIG_HOME/river/init`.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "wayland.windowManager.river" pkgs
        lib.platforms.linux)
    ];

    home.packages = lib.optional (cfg.package != null) cfg.package
      ++ lib.optional cfg.xwayland.enable pkgs.xwayland;

    # Configuration file ~/.config/river/init
    xdg.configFile."river/init".source = pkgs.writeShellScript "init" (''
      ### This file was generated with Nix. Don't modify this file directly.

      ### SHELL VARIABLES ###
      ${config.lib.shell.exportAll cfg.extraSessionVariables}

      ### CONFIGURATION ###
      ${lib.concatStringsSep "\n" (toCommand [ "riverctl" ] cfg.settings)}

      ### EXTRA CONFIGURATION ###
      ${cfg.extraConfig}

    '' + (lib.optionalString cfg.systemd.enable ''
      ### SYSTEMD INTEGRATION ###
      ${systemdActivation}
    ''));

    # Systemd integration
    systemd.user.targets.river-session = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "river compositor session";
        Documentation = [ "man:systemd.special(7)" ];
        BindsTo = [ "graphical-session.target" ];
        Wants = [ "graphical-session-pre.target" ];
        After = [ "graphical-session-pre.target" ];
      };
    };

    systemd.user.targets.tray = {
      Unit = {
        Description = "Home Manager System Tray";
        Requires = [ "graphical-session-pre.target" ];
      };
    };
  };
}
