{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xsession;

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    xsession = {
      enable = mkEnableOption "X Session";

      windowManager.command = mkOption {
        type = types.str;
        example = literalExample ''
          let
            xmonad = pkgs.xmonad-with-packages.override {
              packages = self: [ self.xmonad-contrib self.taffybar ];
            };
          in
            "''${xmonad}/bin/xmonad";
        '';
        description = ''
          Window manager start command.
        '';
      };

      profileExtra = mkOption {
        type = types.lines;
        default = "";
        description = "Extra shell commands to run before session start.";
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
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
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

    # A basic graphical session target for Home Manager.
    systemd.user.targets.hm-graphical-session = {
      Unit = {
        Description = "Home Manager X session";
        Requires = [ "graphical-session-pre.target" ];
        BindsTo = [ "graphical-session.target" ];
      };
    };

    home.file.".xprofile".text = ''
        if [[ -e "$HOME/.profile" ]]; then
          . "$HOME/.profile"
        fi

        # If there are any running services from a previous session.
        # Need to run this in xprofile because the NixOS xsession
        # script starts up graphical-session.target.
        systemctl --user stop graphical-session.target graphical-session-pre.target

        systemctl --user import-environment DBUS_SESSION_BUS_ADDRESS
        systemctl --user import-environment DISPLAY
        systemctl --user import-environment SSH_AUTH_SOCK
        systemctl --user import-environment XAUTHORITY
        systemctl --user import-environment XDG_DATA_DIRS
        systemctl --user import-environment XDG_RUNTIME_DIR
        systemctl --user import-environment XDG_SESSION_ID

        ${cfg.profileExtra}

        export HM_XPROFILE_SOURCED=1
    '';

    home.file.".xsession" = {
      executable = true;
      text = ''
        if [[ ! -v HM_XPROFILE_SOURCED ]]; then
          . ~/.xprofile
        fi
        unset HM_XPROFILE_SOURCED

        systemctl --user start hm-graphical-session.target

        ${cfg.initExtra}

        ${cfg.windowManager.command}

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
