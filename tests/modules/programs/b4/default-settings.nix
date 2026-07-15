{
  # By default the module writes no [b4] git-config at all.
  programs.b4.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/git/config
  '';
}
