{
  config = {
    targets.darwin.terminfo.enable = false;

    nmt.script = ''
      sessionVarsFile=home-path/etc/profile.d/hm-session-vars.sh
      assertFileExists $sessionVarsFile
      assertFileNotRegex $sessionVarsFile 'TERMINFO_DIRS'
      assertFileNotRegex $sessionVarsFile 'export TERM='
    '';
  };
}
