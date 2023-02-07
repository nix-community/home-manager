{ ... }:

{
  programs = {
    scmpuff = {
      enable = true;
      enableBashIntegration = false;
      enableZshIntegration = false;
    };
    bash.enable = true;
    zsh.enable = true;
  };

  test.stubs = {
    zsh = { };
    scmpuff = { };
  };

  nmt.script = ''
    assertFileNotRegex home-files/.zshrc '@scmpuff@ init -s'
    assertFileNotRegex home-files/.bashrc '@scmpuff@ init -s'
  '';
}
