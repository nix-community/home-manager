{
  services.wlsunset = {
    enable = true;
    sunrise = "06:30";
    sunset = "19:00";
    duration = 1800;
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/wlsunset.service

    assertFileExists $serviceFile
    assertFileContent $serviceFile ${builtins.toFile "wlsunset.service" ''
      [Install]
      WantedBy=graphical-session.target

      [Service]
      ExecStart=@wlsunset@/bin/wlsunset -S06:30 -T6500 -d1800 -g1.000000 -s19:00 -t4000

      [Unit]
      After=graphical-session.target
      ConditionEnvironment=WAYLAND_DISPLAY
      Description=Day/night gamma adjustments for Wayland compositors.
      PartOf=graphical-session.target
    ''}
  '';
}
