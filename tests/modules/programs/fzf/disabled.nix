{
  programs.fzf.enable = false;

  nmt.script = ''
    assertPathNotExists home-files/.bashrc
  '';
}
