{ config, lib, pkgs, ... }:

let

  cfg = config.home-manager;

in {
  imports = [ ../nixos/common.nix ];

  config = lib.mkMerge [
    { home-manager.extraSpecialArgs.darwinConfig = config; }
    (lib.mkIf (cfg.users != { }) {
      system.activationScripts.postActivation.text = lib.concatStringsSep "\n"
        (lib.mapAttrsToList (username: usercfg: ''
          echo Activating home-manager configuration for ${username}
          sudo -u ${username} --set-home ${
            pkgs.writeShellScript "activation-${username}" ''
              ${lib.optionalString (cfg.backupFileExtension != null)
              "export HOME_MANAGER_BACKUP_EXT=${
                lib.escapeShellArg cfg.backupFileExtension
              }"}
              ${lib.optionalString cfg.verbose "export VERBOSE=1"}
              exec ${usercfg.home.activationPackage}/activate
            ''
          }
        '') cfg.users);
    })
  ];
}
