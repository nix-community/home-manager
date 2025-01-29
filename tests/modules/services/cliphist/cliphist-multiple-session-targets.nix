{ ... }:

{
  services.cliphist = {
    enable = true;

    systemdTargets = [ "sway-session.target" "hyprland-session.target" ];
  };

  test.stubs = {
    cliphist = { };
    wl-clipboard = { };
  };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/cliphist.service
    assertFileExists home-files/.config/systemd/user/sway-session.target.wants/cliphist.service
    assertFileExists home-files/.config/systemd/user/hyprland-session.target.wants/cliphist.service
  '';
}
