{ config, lib, pkgs, utils, ... }:

with lib;

let

  cfg = config.home-manager;

  serviceEnvironment = optionalAttrs (cfg.backupFileExtension != null) {
    HOME_MANAGER_BACKUP_EXT = cfg.backupFileExtension;
  } // optionalAttrs cfg.verbose { VERBOSE = "1"; };

in {
  imports = [ ./common.nix ];

  options.home-manager = {
    enableLegacyProfileManagement = mkOption {
      type = types.bool;
      default = versionOlder config.system.stateVersion "24.05";
      defaultText = lib.literalMD ''
        - `true` for `system.stateVersion` < 24.05,
        - `false` otherwise'';
      description = ''
        Whether to enable legacy profile (and garbage collection root)
        management during activation. When enabled, the Home Manager activation
        will produce a per-user `home-manager` Nix profile as well as a garbage
        collection root, just like in the standalone installation of Home
        Manager. Typically, this is not desired when Home Manager is embedded in
        the system configuration.
      '';
    };
  };

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

          # Legacy profile management is when the activation script generates GC
          # root and home-manager profile. The modern way simply relies on the
          # GC root that the system maintains, which should also protect the
          # Home Manager activation package outputs.
          home.activationGenerateGcRoot = cfg.enableLegacyProfileManagement;
        }];
      };
    }
    (mkIf (cfg.users != { }) {
      systemd.services = mapAttrs' (_: usercfg:
        let
          username = usercfg.home.username;
          driverVersion =
            if cfg.enableLegacyProfileManagement then "0" else "1";
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
            TimeoutStartSec = "5m";
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

                exec "$1/activate" --driver-version ${driverVersion}
              '';
            in "${setupEnv} ${usercfg.home.activationPackage}";
          };
        }) cfg.users;
    })
  ];
}
