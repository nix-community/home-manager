{ ... }:

{
  programs.tig.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.config/tig/config
    assertPathNotExists home-files/.tigrc
  '';
}
