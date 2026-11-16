{
  home.backupFileExtension = "backup";

  nmt.script = ''
    assertFileContains activate "[[ -v HOME_MANAGER_BACKUP_EXT ]] || export HOME_MANAGER_BACKUP_EXT=backup"
  '';
}
