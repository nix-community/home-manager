{
  home.stateVersion = "19.09";
  programs.zsh = {
    enable = true;
    history.path = "some/directory/zsh_history";
  };

  nmt.script = ''
    assertFileRegex home-files/.zshrc \
      '^HISTFILE="${config.home.homeDirectory}/some/directory/zsh_history"$'
  '';
}
