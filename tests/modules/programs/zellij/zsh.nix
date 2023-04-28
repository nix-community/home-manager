{ ... }:

{
  programs = {
    zellij = {
      enable = true;
      enableZshIntegration = true;
    };
    zsh.enable = true;
  };

  test.stubs = {
    zsh = { };
    zellij = { };
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      'eval "$(zellij setup --generate-auto-start zsh)"'
  '';
}
