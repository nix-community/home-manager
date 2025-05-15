{
  programs.pgcli.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/pgcli/config
  '';
}
