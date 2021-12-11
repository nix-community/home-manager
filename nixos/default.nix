{ config, lib, pkgs, utils, ... }:

with lib;

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
    environment = optionalAttrs (cfg.backupFileExtension != null) {
      HOME_MANAGER_BACKUP_EXT = cfg.backupFileExtension;
    } // optionalAttrs cfg.verbose { VERBOSE = "1"; };
    serviceConfig = baseService username;
  };
  hmDropIn = "/share/systemd/user/home-manager.service.d";

in {
  imports = [ ./common.nix ];
  options.home-manager.useUserService = mkEnableOption
    "activation on each user login instead of every user together on system boot";
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

          # .ssh/config needs to exists before login to let ssh login as that user
          programs.ssh.internallyManaged = lib.mkDefault (!cfg.useUserService);
        }];
      };

      systemd.services = mapAttrs' (_:
        { home, programs, ... }:
        let inherit (home) username homeDirectory;
        in nameValuePair "ssh_config-${utils.escapeSystemdPath username}" {
          enable = with programs.ssh; enable && !internallyManaged;
          description = "Linking ${username}' ssh config";
          wantedBy = [ "multi-user.target" ];
          before = [ "systemd-user-sessions.service" ];

          unitConfig.RequiresMountsFor = homeDirectory;
          stopIfChanged = false;
          serviceConfig = (baseService username) // {
            User = username;
            ExecStart = [
              "${pkgs.coreutils}/bin/mkdir -p ${homeDirectory}/.ssh"
              "${pkgs.coreutils}/bin/ln -s ${programs.ssh.configPath} ${homeDirectory}/.ssh/config"
            ];
          };
        }) cfg.users;
    }
    (mkIf (cfg.users != { } && !cfg.useUserService) {
      systemd.services = mapAttrs' (_: usercfg:
        let inherit (usercfg.home) username homeDirectory activationPackage;
        in nameValuePair "home-manager-${utils.escapeSystemdPath username}"
        (attrsets.recursiveUpdate (baseUnit username) {
          wantedBy = [ "multi-user.target" ];
          wants = [ "nix-daemon.socket" ];
          after = [ "nix-daemon.socket" ];
          before = [ "systemd-user-sessions.service" ];

          unitConfig.RequiresMountsFor = homeDirectory;

          serviceConfig.User = username;
          serviceConfig.ExecStart = let
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
          in "${setupEnv} ${activationPackage}";
        })) cfg.users;
    })
    (mkIf (cfg.users != { } && cfg.useUserService) {
      systemd.user.services.home-manager = (baseUnit "%u") // {
        wantedBy = [ "default.target" ];

        # user units cannot depend on system units
        # TODO: Insert in the script logic for waiting on the nix socket via dbus
        # like https://github.com/mogorman/systemd-lock-handler
        # wants = [ "nix-daemon.socket" ];
        # after = [ "nix-daemon.socket" ];

        unitConfig.RequiresMountsFor = "%h";
        # no ExecStart= is defined for any user that has not defined
        # config.home-manager.users.${username}
        # this will be overridden by the below drop-in
      };

      users.users = mapAttrs (_:
        { home, ... }: {
          # unit files are taken from $XDG_DATA_DIRS too
          # but are loaded after units from /etc
          # we write a drop in so that it will take precedence
          # over the above unit declaration
          packages = [
            (pkgs.writeTextDir "${hmDropIn}/10-user-activation.conf" ''
              [Service]
              ExecStart=${home.activationPackage}/activate
            '')
          ];
        }) cfg.users;
      environment.pathsToLink = [ hmDropIn ];
    })
  ];
}

