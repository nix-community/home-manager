{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    concatStringsSep
    hm
    maintainers
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    platforms
    types
    ;

  cfg = config.wayland.windowManager.dwl;
in
{
  meta.maintainers = with maintainers; [
    glmlm
  ];

  options.wayland.windowManager.dwl = {
    enable = mkEnableOption "dwl, a compact, hackable wayland compositor based on wlroots";

    package = mkPackageOption pkgs "dwl" {
      nullable = true;
      extraDescription = "Set to `null` to not add any dwl package to your path.";
    };

    systemd = {
      enable = mkEnableOption "systemd" // {
        default = true;
        description = ''
          Whether to enable {file}`dwl-session.target` on dwl startup.
          This links to {file}`graphical-session.target`.
        '';
      };

      variables = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Environment variables imported into the systemd and D-Bus user environment.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "wayland.windowManager.dwl" pkgs platforms.linux)
      {
        assertion = cfg.systemd.enable -> cfg.package != null;
        message = "wayland.windowManager.dwl.systemd.enable requires a non-null package";
      }
    ];

    home.packages =
      let
        systemdVariables = concatStringsSep " " cfg.systemd.variables;

        systemdActivation = pkgs.writeShellScript "dwl-startup" ''
          ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd ${systemdVariables}
          ${pkgs.systemd}/bin/systemctl --user import-environment ${systemdVariables}
          ${pkgs.systemd}/bin/systemctl --user reset-failed
          ${pkgs.systemd}/bin/systemctl --user start dwl-session.target
        '';

        dwlWrapped = pkgs.writeShellScriptBin "dwl" ''
          trap "${pkgs.systemd}/bin/systemctl --user stop dwl-session.target" EXIT
          ${cfg.package}/bin/dwl -s ${systemdActivation} "$@"
        '';
      in
      mkIf (cfg.package != null) (if cfg.systemd.enable then [ dwlWrapped ] else [ cfg.package ]);

    systemd.user.targets = mkIf cfg.systemd.enable {
      dwl-session.Unit = {
        Description = "dwl compositor session";
        Documentation = [ "man:systemd.special(7)" ];
        BindsTo = [ "graphical-session.target" ];
        Wants = [ "graphical-session-pre.target" ];
        After = [ "graphical-session-pre.target" ];
      };
    };
  };
}
