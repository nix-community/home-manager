{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    extraOptionOverrides = {
      ForwardAgent = false;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.ssh/config
    assertFileContent \
      home-files/.ssh/config \
      ${./extra-option-overrides-expected.conf}
  '';
}
