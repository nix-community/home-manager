_: {
  time = "2026-09-27T14:11:27+00:00";
  condition = true;
  message = ''
    New options 'home.backupFileExtension', 'home.backupCommand', and
    'home.overwriteBackup' are now available.

    These behave the same as the identically named 'home-manager.*' NixOS
    and nix-darwin module options, but apply to any Home Manager
    configuration, including standalone configurations built with
    'home-manager.lib.homeManagerConfiguration' that are activated without
    going through the 'home-manager' command line tool (for example when
    activated directly or via a tool such as 'deploy-rs').

    They are ignored if the corresponding 'HOME_MANAGER_BACKUP_EXT',
    'HOME_MANAGER_BACKUP_COMMAND', or 'HOME_MANAGER_BACKUP_OVERWRITE'
    environment variable is already set, so the 'home-manager switch -b'
    and '-B' flags continue to take precedence.
  '';
}
