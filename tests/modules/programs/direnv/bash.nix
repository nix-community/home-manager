{
  programs.bash.enable = true;
  programs.direnv.enable = true;

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileRegex \
      home-files/.bashrc \
      'eval "\$(@direnv@/bin/direnv hook bash)"'
  '';
}
