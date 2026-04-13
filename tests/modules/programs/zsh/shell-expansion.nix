{
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      custom = "$HOME/custom oh-my-zsh";
      theme = "$ZSH_THEME_NAME";
      plugins = [ "git" ];
    };
  };

  test.stubs.zsh = { };

  nmt.script = ''
    assertFileContains home-files/.zshrc 'plugins=(git)'
    assertFileContains home-files/.zshrc 'ZSH_CUSTOM="$HOME/custom oh-my-zsh"'
    assertFileContains home-files/.zshrc 'ZSH_THEME="$ZSH_THEME_NAME"'
  '';
}
