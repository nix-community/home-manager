{
  programs.aria2p.enable = false;

  nmt.script = ''
    assertPathNotExists "home-files/.config/aria2p"
  '';
}
