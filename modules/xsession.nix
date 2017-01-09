{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xsession;

in

{
  options = {
    xsession = {
      enable = mkEnableOption "X Session";

      windowManager = mkOption {
        default = {};
        type = types.str;
        description = "Path to window manager to exec.";
      };

      initExtra = mkOption {
        type = types.lines;
        default = "";
        description = "Extra shell commands to run during initialization.";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.setxkbmap = {
      Unit = {
        Description = "Set up keyboard in X";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        Type = "oneshot";
        ExecStart =
          let
            args = concatStringsSep " " (
              [
                "-layout '${config.home.keyboard.layout}'"
                "-variant '${config.home.keyboard.variant}'"
              ] ++
              (map (v: "-option '${v}'") config.home.keyboard.options)
            );
          in
            "${pkgs.xorg.setxkbmap}/bin/setxkbmap ${args}";
      };
    };

    # A basic graphical session target. Apparently this will come
    # standard in future Systemd versions.
    systemd.user.targets.graphical-session = {
      Unit = {
        Description = "Graphical session";
      };
    };

    home.file.".xsession" = {
      mode = "555";
      text = ''
        # Rely on Bash to set session variables.
        . "$HOME/.profile"

        systemctl --user import-environment DBUS_SESSION_BUS_ADDRESS
        systemctl --user import-environment DISPLAY
        systemctl --user import-environment SSH_AUTH_SOCK
        systemctl --user import-environment XAUTHORITY
        systemctl --user import-environment XDG_DATA_DIRS
        systemctl --user import-environment XDG_RUNTIME_DIR
        systemctl --user start graphical-session.target

        ${cfg.initExtra}

        ${cfg.windowManager}

        systemctl --user stop graphical-session.target
      '';
    };
  };
}
