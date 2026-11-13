{
  xdgEnable ? true,
}:
{
  xdg.enable = xdgEnable;
  programs.hyfetch.enable = true;

  nmt.script = ''
    assertPathNotExists "home-files/.config/hyfetch.json"
    assertPathNotExists "home-files/Library/Application Support/hyfetch.json"
  '';
}
