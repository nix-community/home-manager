{
  programs.zsh = {
    enable = false;
    history.path = "some/subdir/.zsh_history";
  };

  nmt.script = ''
    assertPathNotExists home-files/.zshrc
  '';
}
