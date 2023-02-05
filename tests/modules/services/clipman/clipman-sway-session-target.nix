{ ... }:

{
  home.stateVersion = "21.11";

  services.clipman = {
    enable = true;
    systemdTarget = "sway-session.target";
  };

  test.stubs = {
    clipman = { };
    wl-clipboard = { };
  };

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/clipman.service)
    assertFileContent "$serviceFile" ${./clipman-sway-session-target.service}
  '';
}
