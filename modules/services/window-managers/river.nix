{ config, lib, pkgs, ... }:
let
  inherit (lib) types;
  cfg = config.wayland.windowManager.river;

  # Systemd integration
  variables = builtins.concatStringsSep " " cfg.systemd.variables;
  systemdActivation = builtins.concatStringsSep " && " ([
    "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd ${variables}"
  ] ++ (lib.optional cfg.systemd.runInService "systemd-notify --ready")
    ++ cfg.systemd.extraCommands);

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

      runInService = lib.mkEnableOption null // {
        default = false;
        description = ''
          Whether river should run inside systemd (`true`) or outside of systemd
          (`false`).

          Running inside systemd means river lifecycle is fully known/managed by
          systemd. Stopping your computer or river crashing will stop the
          appropriate targets and will make sure everything stays in sync.

          If river runs inside systemd, river logs will be available with
          {command}`journalctl`.

          To start river, you will need to run
          {command}`systemctl --user start river`
          and not run it from the command line.
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
        default = if (!cfg.systemd.runInService) then [
          "systemctl --user stop river-session.target"
          "systemctl --user start river-session.target"
        ] else
          [ ];
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

    '' + (lib.optionalString cfg.systemd.enable ''
      ### SYSTEMD INTEGRATION ###
      ${systemdActivation}
    '') + ''

      ### CONFIGURATION ###
      ${lib.concatStringsSep "\n" (toCommand [ "riverctl" ] cfg.settings)}

      ### EXTRA CONFIGURATION ###
      ${cfg.extraConfig}
    '');

    # Systemd integration
    systemd.user.targets.river-session = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "river compositor session";
        Documentation = [ "man:systemd.special(7)" ];
        BindsTo = [ "graphical-session.target" ];
        Before = [ "graphical-session.target" ];
        Wants = [ "graphical-session-pre.target" ];
        After = [ "graphical-session-pre.target" ];
        RefuseManualStart = if cfg.systemd.runInService then "yes" else "no";
        StopWhenUnneeded = "yes";
      };
    };

    systemd.user.services.river =
      lib.mkIf (cfg.systemd.enable && cfg.systemd.runInService) {
        Unit = {
          Description = "River compositor";
          Documentation = "man:river(1)";
          BindsTo = [ "river-session.target" ];
          Before = [ "river-session.target" ];
        };

        Service = {
          Type = "notify";
          #  /bin/sh -lc is used to get env/session vars (and path).
          ExecStart = "/bin/sh -lc ${pkgs.river}/bin/river";
          TimeoutStopSec = 10;
          NotifyAccess = "all";
          # disable oom killing
          OOMScoreAdjust = -1000;
          ExecStopPost =
            "${pkgs.systemd}/bin/systemctl --user unset-environment ${variables}";
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
