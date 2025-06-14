{ ... }:
{
  programs.delta.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/git/config
  '';
}
