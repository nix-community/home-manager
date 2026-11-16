{
  home.overwriteBackup = true;

  nmt.script = ''
    assertFileContains activate "[[ -v HOME_MANAGER_BACKUP_OVERWRITE ]] || export HOME_MANAGER_BACKUP_OVERWRITE=1"
  '';
}
