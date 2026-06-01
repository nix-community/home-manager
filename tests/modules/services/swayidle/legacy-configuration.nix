{ config, ... }:
{
  # Exercise merging legacy list definitions with new attrset definitions.
  imports = [
    {
      services.swayidle.events.after-resume = "notify-send resumed";
    }
  ];

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

  test.asserts.warnings.expected = [
    ''
      Using `services.swayidle.events` as a list is deprecated and will be
      removed in a future release. Please use an attribute set keyed by event name instead.

      Use event names as attribute keys and commands as values.

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
      ExecStart=@swayidle@/bin/dummy -w after-resume 'notify-send resumed' before-sleep 'swaylock -fF' lock 'swaylock -fF'
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
