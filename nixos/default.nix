{
  config,
  lib,
  pkgs,
  utils,
  ...
}:

let
  cfg = config.home-manager;

  baseService = username: {
    Type = "oneshot";
    RemainAfterExit = "yes";
    TimeoutStartSec = "5m";
    SyslogIdentifier = "hm-activate-${username}";
  };

  baseUnit = username: {
    description = "Home Manager environment for ${username}";
    stopIfChanged = false;
    serviceConfig = baseService username;
    environment =
      {
        # needed to run qt programs like kwriteconfig
        QT_QPA_PLATFORM = "offscreen";
      }
      // lib.optionalAttrs (cfg.backupFileExtension != null) {
        HOME_MANAGER_BACKUP_EXT = cfg.backupFileExtension;
      }
      // lib.optionalAttrs cfg.verbose {
        VERBOSE = "1";
      };
  };

  # we use a service separated from nixos-activation
  # to keep the logs separate
  hmDropIn = "/share/systemd/user/home-manager.service.d";
in
{
  imports = [ ./common.nix ];

  options.home-manager.useUserService = lib.mkEnableOption ''
    Activate each user's environment only when they log in, using a
    systemd user service, instead of activating all configured users'
    environments proactively during boot-up.

    This mode is necessary if users' home directories are not
    available until they log in (for example, when using pam_mount).

    Other usage scenarios are still experimental.  It may speed up
    boot when there are many users; this has not yet been confirmed.
    It could break configurations where the configured users do not
    (or do not always) run their processes within a complete
    systemd-managed user context.
  '';

  config = lib.mkMerge [
    {
      home-manager = {
        extraSpecialArgs.nixosConfig = config;

        sharedModules = [
          {
            key = "home-manager#nixos-shared-module";

            config = {
              # The per-user directory inside /etc/profiles is not known by
              # fontconfig by default.
              fonts.fontconfig.enable = lib.mkDefault (cfg.useUserPackages && config.fonts.fontconfig.enable);
              # Inherit glibcLocales setting from NixOS.
              i18n.glibcLocales = lib.mkDefault config.i18n.glibcLocales;
            };
          }
        ];
      };
    }

    (lib.mkIf (cfg.users != { } && !cfg.useUserService) {
      systemd.services = lib.mapAttrs' (
        _: usercfg:
        let
          inherit (usercfg.home) username homeDirectory activationPackage;
        in
        lib.nameValuePair "home-manager-${utils.escapeSystemdPath username}" (
          lib.attrsets.recursiveUpdate (baseUnit username) {
            wantedBy = [ "multi-user.target" ];
            wants = [ "nix-daemon.socket" ];
            after = [ "nix-daemon.socket" ];
            before = [ "systemd-user-sessions.service" ];

            unitConfig.RequiresMountsFor = homeDirectory;
            serviceConfig.User = username;
            serviceConfig.ExecStart =
              let
                systemctl = "XDG_RUNTIME_DIR=\${XDG_RUNTIME_DIR:-/run/user/$UID} systemctl";
                sed = "${pkgs.gnused}/bin/sed";
                exportedSystemdVariables = lib.concatStringsSep "|" [
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
              in
              "${setupEnv} ${activationPackage}";
          }
        )
      ) cfg.users;
    })

    (lib.mkIf (cfg.users != { } && cfg.useUserService) {
      systemd.user.services.home-manager = (baseUnit "%u") // {
        # user units cannot depend on system units
        # TODO: Insert in the script logic for waiting on the nix socket
        # via dbus like https://github.com/mogorman/systemd-lock-handler
        #wants = [ "nix-daemon.socket" ];
        #after = [ "nix-daemon.socket" ];
        unitConfig.RequiresMountsFor = "%h";
        # no ExecStart= is defined for any user that has not defined
        # config.home-manager.users.${username}
        # this will be overridden by the below drop-in
      };

      users.users = lib.mapAttrs (
        _:
        { home, ... }:
        {
          # unit files are taken from $XDG_DATA_DIRS too, but are
          # loaded after units from /etc.  We write a drop in so that
          # it will take precedence over the above unit declaration.
          # Because this unit will be run in the user context, it does
          # not need the wrapper script that's used when activation is
          # done by system units.
          packages = [
            (pkgs.writeTextDir "${hmDropIn}/10-user-activation.conf" ''
              [Service]
              ExecStart=${home.activationPackage}/activate
            '')
          ];
        }
      ) cfg.users;

      environment.pathsToLink = [ hmDropIn ];

      # Without this will not reload home conf
      # of logged user on system activation
      # it will also start the unit on startup
      system.userActivationScripts.home-manager = {
        text = "${pkgs.systemd}/bin/systemctl --user restart home-manager";
        deps = [ ];
      };
    })
  ];
}
