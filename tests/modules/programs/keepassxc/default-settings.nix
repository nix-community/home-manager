{ ... }:

{
  programs.keepassxc = {
    enable = true;
  };

  test.stubs.keepassxc = { };

  nmt.script = ''
    assertPathNotExists home-files/.config/keepassxc/keepassxc.ini
  '';
}
