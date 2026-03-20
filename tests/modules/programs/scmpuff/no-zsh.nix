{
  programs = {
    scmpuff = {
      enable = true;
      enableZshIntegration = false;
    };
    zsh.enable = true;
  };

  nmt.script = ''
    assertFileNotRegex home-files/.zshrc '@scmpuff@ init -s'
  '';
}
