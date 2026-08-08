{
  programs = {
    worktrunk.enable = true;
    bash.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileRegex home-files/.bashrc \
      'eval "\$(@worktrunk@/bin/wt config shell init bash)"'
  '';
}
