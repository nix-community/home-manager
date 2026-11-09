{
  programs.oyui = {
    enable = true;
    package = null;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/oyui/config.rn
  '';
}
