{
  programs.qcal = {
    enable = true;
    settings = {
      DefaultNumDays = 23;
      Timezone = "Europe/Berlin";
    };
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

  nmt.script = ''
    assertFileExists home-files/.config/qcal/config.json
    assertFileContent home-files/.config/qcal/config.json ${./webdav-calendar.json-expected}
  '';
}
