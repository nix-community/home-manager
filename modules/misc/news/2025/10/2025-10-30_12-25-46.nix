{
  time = "2025-10-30T17:25:46+00:00";
  condition = true;
  message = ''
    A new option 'backupCommand' is now available for Home Manager activation.

    This option allows you to specify a custom command to run on existing files
    during activation. If set, it takes precedence over 'backupFileExtension',
    but can work together with it by referencing the '$HOME_MANAGER_BACKUP_EXT'
    environment variable in your command.

    This enables advanced backup workflows, such as moving files to trash or
    archiving with custom tools, before managing them with Home Manager.

    The option is available in standalone, NixOS, and nix-darwin configurations.
  '';
}
