{ ... }:

{
  programs = {
    scmpuff.enable = true;
    bash.enable = true;
  };

  test.stubs.scmpuff = { };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      'eval "$(@scmpuff@/bin/scmpuff init -s)"'
  '';
}
