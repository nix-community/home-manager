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
      auth.userName = "anton";
      auth.passwordCommand = [ "pass" "show" "calendar" ];
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/qcal/config.json
    assertFileContent home-files/.config/qcal/config.json ${
      ./webdav-calendar.json-expected
    }
  '';
}
