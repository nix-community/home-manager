{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) types;
  cfg = config.wayland.windowManager.river;

  # Systemd integration
  variables = builtins.concatStringsSep " " cfg.systemd.variables;
  extraCommands = builtins.concatStringsSep " " (map (f: "&& ${f}") cfg.systemd.extraCommands);
  systemdActivation = ''
    ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd ${variables} ${extraCommands}
  '';
in
{
  meta.maintainers = [ lib.maintainers.shunueda ];

  imports = [
    (lib.mkRemovedOptionModule [ "wayland" "windowManager" "river" "settings" ] ''
      River 0.4 and later no longer provide `riverctl`. Use
      `wayland.windowManager.river-classic` for river 0.3, or start a window
      manager from `wayland.windowManager.river.extraConfig`.'')
    (lib.mkRemovedOptionModule [ "wayland" "windowManager" "river" "xwayland" "enable" ] ''
      XWayland support is built into the river package. Use
      `wayland.windowManager.river-classic` for river 0.3.'')
  ];

  options.wayland.windowManager.river = {
    enable = lib.mkEnableOption "river, a non-monolithic Wayland compositor";

    package = lib.mkPackageOption pkgs "river" {
      nullable = true;
      extraDescription = ''
        Set to `null` to not add any river package to your path.
        This should be done if you want to use the NixOS river module to install river.
      '';
    };

    systemd = {
      enable = lib.mkEnableOption null // {
        default = true;
        description = ''
          Whether to enable {file}`river-session.target` on
          river startup. This links to {file}`graphical-session.target`.
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
      example = {
        MOZ_ENABLE_WAYLAND = "1";
      };
    };

    extraConfig = lib.mkOption {
      type = types.lines;
      default = "";
      example = ''
        exec my-window-manager
      '';
      description = ''
        Extra lines appended to {file}`$XDG_CONFIG_HOME/river/init`.
        River does not manage windows on its own, so this should start a
        window manager implementing the river-window-management-v1 protocol.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "wayland.windowManager.river" pkgs lib.platforms.linux)
    ];

    home.packages = lib.optional (cfg.package != null) cfg.package;

    # Configuration file ~/.config/river/init
    xdg.configFile."river/init".source = pkgs.writeShellScript "init" (
      ''
        ### This file was generated with Nix. Don't modify this file directly.

        ### SHELL VARIABLES ###
        ${config.lib.shell.exportAll ({ XDG_CURRENT_DESKTOP = "river"; } // cfg.extraSessionVariables)}

      ''
      + (lib.optionalString cfg.systemd.enable ''
        ### SYSTEMD INTEGRATION ###
        ${systemdActivation}
      '')
      + ''
        ### EXTRA CONFIGURATION ###
        ${cfg.extraConfig}''
    );

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
  };
}
