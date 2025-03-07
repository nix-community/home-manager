{
  services.blanket.enable = true;

  nmt.script = ''
    clientServiceFile=home-files/.config/systemd/user/blanket.service

    assertFileExists $clientServiceFile
    assertFileContent $clientServiceFile ${
      builtins.toFile "expected.service" ''
        [Install]
        WantedBy=graphical-session.target

        [Service]
        ExecStart=@blanket@/bin/blanket --gapplication-service
        Restart=on-failure
        RestartSec=5

        [Unit]
        After=graphical-session-pre.target
        Description=Blanket daemon
        PartOf=graphical-session.target
        PartOf=pipewire.service
        Requires=dbus.service
      ''
    }
  '';
}
