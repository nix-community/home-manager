{ ... }:

{
  services.avizo.enable = true;

  test.stubs.avizo = { };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/avizo.service
    assertFileExists $serviceFile
    assertFileContent $serviceFile ${
      builtins.toFile "expected" ''
        [Install]
        WantedBy=graphical-session.target

        [Service]
        ExecStart=@avizo@/bin/avizo-service
        Restart=always
        Type=simple

        [Unit]
        After=graphical-session.target
        ConditionEnvironment=WAYLAND_DISPLAY
        Description=Volume/backlight OSD indicator
        Documentation=man:avizo(1)
        PartOf=graphical-session.target
      ''
    }

    configFile=home-files/.config/avizo/config.ini
    assertPathNotExists $configFile
  '';
}
