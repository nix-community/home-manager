{ config, ... }:
{
  services.swayidle = {
    enable = true;
    package = config.lib.test.mkStubPackage { outPath = "@swayidle@"; };
    events = [
      {
        event = "lock";
        command = "swaylock -fF";
      }
      {
        event = "before-sleep";
        command = "swaylock -fF";
      }
    ];
  };

  test.asserts.evalWarnings.expected = [
    ''
      The syntax of services.swayidle.events has changed. While it
      previously accepted a list of events, it now accepts an attrset
      keyed by the event name.
    ''
  ];

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/swayidle.service

    assertFileExists "$serviceFile"

    serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"

    assertFileContent "$serviceFileNormalized" ${builtins.toFile "expected.service" ''
      [Install]
      WantedBy=graphical-session.target

      [Service]
      Environment=PATH=@bash-interactive@/bin
      ExecStart=@swayidle@/bin/dummy -w before-sleep 'swaylock -fF' lock 'swaylock -fF'
      Restart=always
      Type=simple

      [Unit]
      After=graphical-session.target
      ConditionEnvironment=WAYLAND_DISPLAY
      Description=Idle manager for Wayland
      Documentation=man:swayidle(1)
      PartOf=graphical-session.target
    ''}
  '';
}
