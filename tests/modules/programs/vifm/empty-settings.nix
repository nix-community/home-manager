{ ... }:

{
  programs.vifm.enable = true;

  test.stubs.vifm = { };

  nmt.script = ''
    assertPathNotExists home-files/.config/vifm
  '';
}
