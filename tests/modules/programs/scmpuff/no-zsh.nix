{ ... }:

{
  programs = {
    scmpuff = {
      enable = true;
      enableZshIntegration = false;
    };
    zsh.enable = true;
  };

  test.stubs = {
    zsh = { };
    scmpuff = { };
  };

  nmt.script = ''
    assertFileNotRegex home-files/.zshrc '@scmpuff@ init -s'
  '';
}
