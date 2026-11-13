{
  # home.backupFileExtension, home.backupCommand, and home.overwriteBackup
  # default to null/false, so none of the corresponding env vars should be
  # exported by the activation script.

  nmt.script = ''
    assertFileNotRegex activate "HOME_MANAGER_BACKUP_EXT"
    assertFileNotRegex activate "HOME_MANAGER_BACKUP_COMMAND"
    assertFileNotRegex activate "HOME_MANAGER_BACKUP_OVERWRITE"
  '';
}
