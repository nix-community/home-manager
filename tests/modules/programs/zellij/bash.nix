{ ... }:

{
  programs = {
    zellij = {
      enable = true;
      enableBashIntegration = true;
    };
    bash.enable = true;
  };

  test.stubs = { zellij = { }; };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      'eval "$(zellij setup --generate-auto-start bash)"'
  '';
}
