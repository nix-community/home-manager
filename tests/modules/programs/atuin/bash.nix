{
  programs = {
    atuin.enable = true;
    bash = {
      enable = true;
      enableCompletion = false;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      'eval "$(@atuin@/bin/atuin init bash )"'
  '';
}
