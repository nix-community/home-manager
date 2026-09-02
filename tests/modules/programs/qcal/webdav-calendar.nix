{ lib, options, ... }:
{
  programs.qcal = {
    enable = true;
    defaultNumDays = 23;
    timezone = "Europe/Berlin";
  };
  accounts.calendar.accounts.test = {
    qcal.enable = true;
    remote = {
      url = "https://cal.example.com/anton/work";
      userName = "anton";
      passwordCommand = [
        "pass"
        "show"
        "calendar"
      ];
    };
  };

  test.asserts.warnings.expected = [
    "The option `programs.qcal.defaultNumDays' defined in ${lib.showFiles options.programs.qcal.defaultNumDays.files} has been renamed to `programs.qcal.settings.DefaultNumDays'."
    "The option `programs.qcal.timezone' defined in ${lib.showFiles options.programs.qcal.timezone.files} has been renamed to `programs.qcal.settings.Timezone'."
  ];

  nmt.script = ''
    assertFileExists home-files/.config/qcal/config.json
    assertFileContent home-files/.config/qcal/config.json ${./webdav-calendar.json-expected}
  '';
}
