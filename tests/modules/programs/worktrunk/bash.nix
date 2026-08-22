{
  programs = {
    worktrunk.enable = true;
    worktrunk.enableBashIntegration = true;
    bash.enable = true;
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      'eval "$(@worktrunk@ config shell init bash)"'
  '';
}
