{ ... }:

{
  programs.k9s.enable = true;

  test.stubs.k9s = { };

  nmt.script = ''
    assertPathNotExists home-files/.config/k9s
  '';
}
