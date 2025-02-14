{
  services.cliphist = {
    enable = true;

    systemdTargets = [ "sway-session.target" "hyprland-session.target" ];
  };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/cliphist.service
    assertFileExists home-files/.config/systemd/user/sway-session.target.wants/cliphist.service
    assertFileExists home-files/.config/systemd/user/hyprland-session.target.wants/cliphist.service
  '';
}
