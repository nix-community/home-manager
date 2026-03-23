{ ... }:
{
  programs.feedr.enable = false;

  nmt.script = ''
    assertPathNotExists "home-files/.config/feedr"
  '';
}
