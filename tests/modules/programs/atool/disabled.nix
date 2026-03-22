{ ... }:
{
  programs.atool.enable = false;

  nmt.script = ''
    assertPathNotExists "home-files/.atoolrc"
  '';
}
