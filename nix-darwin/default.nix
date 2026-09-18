{
  config,
  lib,
  options,
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
      home-manager.extraSpecialArgs.darwinConfig = config;
      warnings =
        lib.optional
          (
            cfg.useUserPackages
            && !(config.programs.fish.enable or false)
            && (options.programs.fish.enable.highestPrio or 1500) >= 1500
            && lib.any (user: user.programs.fish.enable or false) (lib.attrValues cfg.users)
          )
          ''
            Home Manager fish users may be missing package-provided completions.
            Set programs.fish.enable = true in your nix-darwin configuration,
            outside home-manager.users, to enable vendor profile links and early
            shell environment setup. If you manage this integration yourself,
            explicitly set nix-darwin's programs.fish.enable = false to silence
            this warning.
          '';
    }
    (lib.mkIf (cfg.users != { }) {
      system.activationScripts.postActivation.text = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          _username: usercfg:
          let
            driverVersion = if cfg.enableLegacyProfileManagement then "0" else "1";
          in
          ''
            echo Activating home-manager configuration for ${usercfg.home.username} >&2
            hmDryRunArgs=()
            hmParentArgs="$(ps -p "$PPID" -ww -o args= || true)"
            if [[ -v DRY_RUN || "$hmParentArgs" == *" --dry-run"* ]]; then
              hmDryRunArgs=(env DRY_RUN=1)
            fi
            launchctl asuser "$(id -u ${usercfg.home.username})" sudo -u ${usercfg.home.username} --set-home "''${hmDryRunArgs[@]}" ${pkgs.writeShellScript "activation-${usercfg.home.username}" ''
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
