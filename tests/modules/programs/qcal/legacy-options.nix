{ lib, options, ... }:
{
  programs.qcal = {
    enable = true;
    defaultNumDays = 23;
    timezone = "Europe/Berlin";
    settings.Calendars = [
      { Url = "https://example.com/events.ical"; }
    ];
  };

  accounts.calendar.accounts.ignored = {
    qcal.enable = true;
    remote.url = "https://ignored.example.com/events.ical";
  };

  test.asserts.warnings.expected = [
    "The option `programs.qcal.defaultNumDays' defined in ${lib.showFiles options.programs.qcal.defaultNumDays.files} has been renamed to `programs.qcal.settings.DefaultNumDays'."
    "The option `programs.qcal.timezone' defined in ${lib.showFiles options.programs.qcal.timezone.files} has been renamed to `programs.qcal.settings.Timezone'."
  ];

  nmt.script = ''
    assertFileContent home-files/.config/qcal/config.json ${./legacy-options.json-expected}
  '';
}
