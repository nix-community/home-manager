{ ... }:

{
  programs = {
    zellij.enable = true;
    zsh.enable = true;
  };

  test.stubs = {
    zsh = { };
    zellij = { };
  };

  nmt.script = ''
    assertFileNotRegex home-files/.zshrc \
      'eval "$(zellij setup --generate-auto-start zsh)"'
  '';
}
