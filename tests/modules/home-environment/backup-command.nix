{
  home.backupCommand = "/bin/true";

  nmt.script = ''
    assertFileContains activate "[[ -v HOME_MANAGER_BACKUP_COMMAND ]] || export HOME_MANAGER_BACKUP_COMMAND=/bin/true"
  '';
}
