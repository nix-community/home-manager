{ config, lib, pkgs, ... }:

# Largely based on adnan360's power.sh gist:
# https://gist.github.com/adnan360/f86012baeb4c9ca4f1af033550b03033
#
# Depends on rofi

with lib;

let
  cfg = config.programs.rofi.power;
  rofi-power = { states, logoutCmd }:
    pkgs.writeScriptBin "rofi-power" ''
      #!${pkgs.stdenv.shell}
      chosen=$(cat <<EOF | rofi -dmenu -i
      ${states}
      EOF
      )

      if [[ $chosen == "Logout" ]]; then
        ${logoutCmd}
      elif [[ $chosen == "Shutdown" ]]; then
        systemctl poweroff
      elif [[ $chosen == "Reboot" ]]; then
        systemctl reboot
      elif [[ $chosen == "Suspend" ]]; then
        systemctl suspend
      elif [[ $chosen == "Hibernate" ]]; then
        systemctl hibernate
      elif [[ $chosen == "Hybrid-sleep" ]]; then
        systemctl hibernate
      elif [[ $chosen == "Suspend-then-hibernate" ]]; then
        systemctl suspend-then-hibernate
      fi
    '';

in {
  meta.maintainers = [ maintainers.seylerius ];

  options = {
    programs.rofi.power = {
      enable = mkEnableOption "Power menu based on rofi and systemd";

      logoutCommand = mkOption {
        default = "";
        type = types.str;
        description =
          "The command used to logout. Required if the Logout state is enabled.";
      };

      # validation = mkSinkUndeclaredOptions { description = "Sink for validation assert"; };

      # Allow toggling of individual power states
      states = {
        logout = mkOption {
          default = true;
          type = lib.types.bool;
          description = "Toggle for Logout target";
        };
        shutdown = mkOption {
          default = true;
          type = lib.types.bool;
          description = "Toggle for Shutdown target";
        };
        reboot = mkOption {
          default = true;
          type = lib.types.bool;
          description = "Toggle for Reboot target";
        };
        suspend = mkOption {
          default = true;
          type = lib.types.bool;
          description = "Toggle for Suspend target";
        };
        hibernate = mkOption {
          default = true;
          type = lib.types.bool;
          description = "Toggle for Hibernate target";
        };
        hybridSleep = mkOption {
          default = true;
          type = lib.types.bool;
          description = "Toggle for Hybrid-sleep target";
        };
        suspendThenHibernate = mkOption {
          default = true;
          type = lib.types.bool;
          description = "Toggle for Suspend-then-Hibernate target";
        };
      };
    };
  };

  config =
    mkIf (cfg.enable && (cfg.states.logout -> (cfg.logoutCommand != ""))) {
      # programs.rofi.power.validation = assert (cfg.states.logout -> (cfg.logoutCommand != null)); cfg.logoutCommand;
      home.packages = [
        (rofi-power {
          states = (pkgs.lib.concatStringsSep "\n" ([ "[Cancel]" ]
            ++ optionals cfg.states.logout [ "Logout" ]
            ++ optionals cfg.states.shutdown [ "Shutdown" ]
            ++ optionals cfg.states.reboot [ "Reboot" ]
            ++ optionals cfg.states.suspend [ "Suspend" ]
            ++ optionals cfg.states.hibernate [ "Hibernate" ]
            ++ optionals cfg.states.hybridSleep [ "Hybrid-sleep" ]
            ++ optionals cfg.states.suspendThenHibernate
            [ "Suspend-then-hibernate" ]));
          logoutCmd = cfg.logoutCommand;
        })
      ];
    };
}
