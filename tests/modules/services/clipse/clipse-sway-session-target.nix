{ ... }:

{
  services.clipse = {
    enable = true;
    systemdTarget = "sway-session.target";
  };

  test.stubs = {
    clipse = { };
    wl-clipboard = { };
  };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/clipse.service
  '';
}
