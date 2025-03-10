{
  programs = {
    scmpuff.enable = true;
    bash.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      'eval "$(@scmpuff@/bin/scmpuff init --shell=bash)"'
  '';
}
