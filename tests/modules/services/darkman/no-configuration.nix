{
  services.darkman.enable = true;

  test.stubs = {
    python = { };
    darkman = { };
  };

  nmt.script = ''
    serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/darkman.service)

    assertFileExists $serviceFile
    assertFileContent $serviceFile ${
      builtins.toFile "expected" ''
        [Install]
        WantedBy=graphical-session.target

        [Service]
        BusName=nl.whynothugo.darkman
        ExecStart=@darkman@/bin/dummy run
        Restart=on-failure
        Slice=background.slice
        TimeoutStopSec=15
        Type=dbus

        [Unit]
        BindsTo=graphical-session.target
        Description=Darkman system service
        Documentation=man:darkman(1)
        PartOf=graphical-session.target
      ''
    }
    assertPathNotExists home-files/.local/share/dark-mode.d/color-scheme-dark
    assertPathNotExists home-files/.local/share/light-mode.d/color-scheme-light
  '';
}

