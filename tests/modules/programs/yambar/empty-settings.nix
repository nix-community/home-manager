{ ... }:

{
  programs.yambar.enable = true;

  test.stubs.yambar = { };

  nmt.script = ''
    assertPathNotExists home-files/.config/yambar
  '';
}
