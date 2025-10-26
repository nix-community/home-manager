{
  programs.gcc = {
    enable = true;
    colors = {
      error = "01;31";
      warning = "01;33";
      note = "01;36";
      caret = "01;32";
      locus = "01";
      quote = "01";
    };
  };

  nmt.script = ''
    hmEnvFile=home-path/etc/profile.d/hm-session-vars.sh
    assertFileExists $hmEnvFile
    assertFileRegex $hmEnvFile 'export GCC_COLORS="caret=01;32:error=01;31:locus=01:note=01;36:quote=01:warning=01;33"'
  '';
}
