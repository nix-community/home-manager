{ ... }:
{
  programs.sunpaper.enable = false;

  nmt.script = ''
    assertPathNotExists "home-files/.config/sunpaper/config"
  '';
}
