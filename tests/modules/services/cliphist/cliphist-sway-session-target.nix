{ ... }:

{
  services.cliphist = {
    enable = true;
    systemdTarget = "sway-session.target";
  };

  test.stubs = {
    cliphist = { };
    wl-clipboard = { };
  };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/cliphist.service
  '';
}
