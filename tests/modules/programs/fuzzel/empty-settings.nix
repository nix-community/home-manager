{ ... }:

{
  programs.fuzzel.enable = true;

  test.stubs.fuzzel = { };

  nmt.script = ''
    assertPathNotExists home-files/.config/fuzzel
  '';
}
