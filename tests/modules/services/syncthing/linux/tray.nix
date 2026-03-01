{
  services.syncthing.tray.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/syncthingtray.service
    assertFileContent \
      home-files/.config/systemd/user/syncthingtray.service \
      ${builtins.toFile "syncthingtray-expected.service" ''
        [Install]
        WantedBy=graphical-session.target

        [Service]
        ExecStart=@syncthingtray@/bin/syncthingtray --wait

        [Unit]
        After=graphical-session.target
        After=tray-sni.target
        After=tray-watcher.service
        Description=syncthingtray
        PartOf=graphical-session.target
        Requires=tray-sni.target
        Wants=tray-watcher.service
      ''}
  '';
}
