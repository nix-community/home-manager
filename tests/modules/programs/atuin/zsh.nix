{ ... }:

{
  programs = {
    atuin.enable = true;
    zsh.enable = true;
  };

  test.stubs = {
    atuin = { };
    bash-preexec = { };
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'eval "$(@atuin@/bin/atuin init zsh)"'
  '';
}
