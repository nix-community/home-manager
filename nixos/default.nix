{ config, lib, pkgs, utils, ... }:

with lib;

let

  cfg = config.home-manager;

  serviceEnvironment = optionalAttrs (cfg.backupFileExtension != null) {
    HOME_MANAGER_BACKUP_EXT = cfg.backupFileExtension;
  } // optionalAttrs cfg.verbose { VERBOSE = "1"; };

in {
  imports = [ ./common.nix ];

  config = mkMerge [
    {
      home-manager = {
        extraSpecialArgs.nixosConfig = config;

        sharedModules = [{
          # The per-user directory inside /etc/profiles is not known by
          # fontconfig by default.
          fonts.fontconfig.enable = lib.mkDefault
            (cfg.useUserPackages && config.fonts.fontconfig.enable);

          # Inherit glibcLocales setting from NixOS.
          i18n.glibcLocales = lib.mkDefault config.i18n.glibcLocales;
        }];
      };
    }
    (mkIf (cfg.users != { }) {
      systemd.services = mapAttrs' (_: usercfg:
        let username = usercfg.home.username;
        in nameValuePair ("home-manager-${utils.escapeSystemdPath username}") {
          description = "Home Manager environment for ${username}";
          wantedBy = [ "multi-user.target" ];
          wants = [ "nix-daemon.socket" ];
          after = [ "nix-daemon.socket" ];
          before = [ "systemd-user-sessions.service" ];

          environment = serviceEnvironment;

          unitConfig = { RequiresMountsFor = usercfg.home.homeDirectory; };

          stopIfChanged = false;

          serviceConfig = {
            User = usercfg.home.username;
            Type = "oneshot";
            RemainAfterExit = "yes";
            TimeoutStartSec = 90;
            SyslogIdentifier = "hm-activate-${username}";

            ExecStart = let
              systemctl =
                "XDG_RUNTIME_DIR=\${XDG_RUNTIME_DIR:-/run/user/$UID} systemctl";

              sed = "${pkgs.gnused}/bin/sed";

              exportedSystemdVariables = concatStringsSep "|" [
                "DBUS_SESSION_BUS_ADDRESS"
                "DISPLAY"
                "WAYLAND_DISPLAY"
                "XAUTHORITY"
                "XDG_RUNTIME_DIR"
              ];

              setupEnv = pkgs.writeScript "hm-setup-env" ''
                #! ${pkgs.runtimeShell} -el

                # The activation script is run by a login shell to make sure
                # that the user is given a sane environment.
                # If the user is logged in, import variables from their current
                # session environment.
                eval "$(
                  ${systemctl} --user show-environment 2> /dev/null \
                  | ${sed} -En '/^(${exportedSystemdVariables})=/s/^/export /p'
                )"

                exec "$1/activate"
              '';
            in "${setupEnv} ${usercfg.home.activationPackage}";
          };
        }) cfg.users;
    })
  ];
}
