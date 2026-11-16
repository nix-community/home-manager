{
  programs.qcal = {
    enable = true;
    settings = {
      DefaultNumDays = 7;
      Timezone = "Europe/Paris";
      Custom = true;
    };
  };

  accounts.calendar.accounts = {
    work = {
      qcal = {
        enable = true;
        settings = {
          Name = "Work";
          Username = "override";
        };
      };
      remote = {
        url = "https://cal.example.com/work";
        userName = "anton";
        passwordCommand = [
          "pass"
          "show"
          "work"
        ];
      };
    };
    disabled = {
      qcal.settings.Name = "Disabled";
      remote.url = "https://disabled.example.com/events.ical";
    };
    local.qcal = {
      enable = true;
      settings = {
        Name = "Local";
        Url = "https://local.example.com/events.ical";
      };
    };
  };

  nmt.script = ''
    assertFileContent home-files/.config/qcal/config.json ${./settings.json-expected}
  '';
}
