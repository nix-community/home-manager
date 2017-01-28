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

    # For stuff that needs to start just before a graphical session
    # starts.
    systemd.user.targets.graphical-session-pre = {
      Unit = {
        Description = "Pre-graphical session";
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
        if [[ -e "$HOME/.profile" ]]; then
          . "$HOME/.profile"
        fi

        systemctl --user import-environment DBUS_SESSION_BUS_ADDRESS
        systemctl --user import-environment DISPLAY
        systemctl --user import-environment SSH_AUTH_SOCK
        systemctl --user import-environment XAUTHORITY
        systemctl --user import-environment XDG_DATA_DIRS
        systemctl --user import-environment XDG_RUNTIME_DIR

        systemctl --user restart graphical-session-pre.target
        systemctl --user restart graphical-session.target

        ${cfg.initExtra}

        ${cfg.windowManager}

        systemctl --user stop graphical-session.target
        systemctl --user stop graphical-session-pre.target

        # Wait until the units actually stop.
        while [[ -n "$(systemctl --user --no-legend --state=deactivating list-units)" ]]; do
          sleep 0.5
        done
      '';
    };
  };
}
