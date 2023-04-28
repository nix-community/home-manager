{ ... }:

{
  programs = {
    zellij.enable = true;
    bash.enable = true;
  };

  test.stubs = {
    zellij = { };
  };

  nmt.script = ''
    assertFileNotRegex home-files/.bashrc \
      'eval "$(zellij setup --generate-auto-start bash)"'
  '';
}
