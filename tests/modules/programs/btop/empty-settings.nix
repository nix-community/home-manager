{ ... }:

{
  programs.btop.enable = true;

  test.stubs.btop = { };

  nmt.script = ''
    assertPathNotExists home-files/.config/btop
  '';
}
