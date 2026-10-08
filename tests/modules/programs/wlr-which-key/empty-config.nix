{
  programs.wlr-which-key = {
    enable = true;
  };
  nmt.script = ''
    assertPathNotExists home-files/.config/wlr-which-key
  '';
}
