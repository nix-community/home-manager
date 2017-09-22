{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xsession;

  # Hack to support xsession.windowManager.command option.
  wmBaseModule = {
    options = {
      command = mkOption {
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

      usesDeprecated = mkOption {
        internal = true;
        type = types.bool;
        default = false;
      };
    };
  };

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    xsession = {
      enable = mkEnableOption "X Session";

      windowManager = mkOption {
        type =
          types.coercedTo
            types.str
            (command: { inherit command; usesDeprecated = true; })
            (types.submodule wmBaseModule);
        description = ''
          Window manager start command. DEPRECATED: Use
          <varname>xsession.windowManager.command</varname> instead.
        '';
      };

      initExtra = mkOption {
        type = types.lines;
        default = "";
        description = "Extra shell commands to run during initialization.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.windowManager.usesDeprecated {
      warnings = [
        ("xsession.windowManager is deprecated, "
          + "please use xsession.windowManager.command")
      ];
    })

    {
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

      home.file.".xsession" = {
        mode = "555";
        text = ''
          if [[ -e "$HOME/.profile" ]]; then
            . "$HOME/.profile"
          fi

          # If there are any running services from a previous session.
          systemctl --user stop graphical-session.target graphical-session-pre.target

          systemctl --user import-environment DBUS_SESSION_BUS_ADDRESS
          systemctl --user import-environment DISPLAY
          systemctl --user import-environment SSH_AUTH_SOCK
          systemctl --user import-environment XAUTHORITY
          systemctl --user import-environment XDG_DATA_DIRS
          systemctl --user import-environment XDG_RUNTIME_DIR
          systemctl --user import-environment XDG_SESSION_ID

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
    }
  ]);
}
