{ realPkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    package = realPkgs.ghostty;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/ghostty/config
  '';
}
