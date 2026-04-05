{ ... }:

{
  programs.tig = {
    enable = false;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/tig/config
    assertPathNotExists home-files/.tigrc
  '';
}
