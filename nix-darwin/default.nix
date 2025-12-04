{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.home-manager;

in
{
  imports = [ ../nixos/common.nix ];

  config = lib.mkMerge [
    {
      home-manager = {
        extraSpecialArgs.darwinConfig = config;

        sharedModules = [
          (
            { name, ... }:
            {
              key = "home-manager#darwin-shared-module";

              config = {
                home.uid = lib.mkIf (config.users.users.${name} ? uid) config.users.users.${name}.uid;
              };
            }
          )
        ];
      };
    }
    (lib.mkIf (cfg.users != { }) {
      system.activationScripts.postActivation.text = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          username: usercfg:
          let
            driverVersion = if cfg.enableLegacyProfileManagement then "0" else "1";
          in
          ''
            echo Activating home-manager configuration for ${usercfg.home.username} >&2
            launchctl asuser "$(id -u ${usercfg.home.username})" sudo -u ${usercfg.home.username} --set-home ${pkgs.writeShellScript "activation-${usercfg.home.username}" ''
              ${lib.optionalString (
                cfg.backupFileExtension != null
              ) "export HOME_MANAGER_BACKUP_EXT=${lib.escapeShellArg cfg.backupFileExtension}"}
              ${lib.optionalString (
                cfg.backupCommand != null
              ) "export HOME_MANAGER_BACKUP_COMMAND=${lib.escapeShellArg cfg.backupCommand}"}
              ${lib.optionalString cfg.overwriteBackup "export HOME_MANAGER_BACKUP_OVERWRITE=1"}
              ${lib.optionalString cfg.verbose "export VERBOSE=1"}
              exec ${usercfg.home.activationPackage}/activate --driver-version ${driverVersion} >&2
            ''}
          ''
        ) cfg.users
      );
    })
  ];
}
