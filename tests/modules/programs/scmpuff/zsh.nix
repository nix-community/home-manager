{ ... }:

{
  programs = {
    scmpuff.enable = true;
    zsh.enable = true;
  };

  test.stubs = {
    zsh = { };
    scmpuff = { };
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'eval "$(@scmpuff@/bin/scmpuff init -s)"'
  '';
}
