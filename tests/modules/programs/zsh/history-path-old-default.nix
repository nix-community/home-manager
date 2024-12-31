{
  home.stateVersion = "19.03";
  programs.zsh.enable = true;

  nmt.script = ''
    assertFileRegex home-files/.zshrc \
      '^HISTFILE="${config.home.homeDirectory}/.zsh_history"$'
  '';
}
