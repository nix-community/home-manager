{
  programs.qcal = {
    enable = true;
    settings = {
      Calendars = [
        { Password = "root-secret"; }
      ];
      DefaultNumDays = 7;
      Timezone = "Europe/Paris";
      Custom = true;
    };
  };

  accounts.calendar.accounts = {
    enabled = {
      qcal = {
        enable = true;
        settings = {
          Name = "Enabled";
          Password = "account-secret";
        };
      };
      remote.url = "https://example.com/events.ical";
    };
    disabled = {
      qcal.settings.Name = "Disabled";
      remote.url = "https://disabled.example.com/events.ical";
    };
  };

  nmt.script = ''
    assertFileContent home-files/.config/qcal/config.json ${builtins.toFile "qcal-settings.expected" ''
      {
        "Calendars": [
          {
            "Password": "root-secret"
          }
        ],
        "Custom": true,
        "DefaultNumDays": 7,
        "Timezone": "Europe/Paris"
      }
    ''}
  '';

  test.asserts.warnings.expected = [
    "qcal: `programs.qcal.settings.Calendars[0].Password` is written to the Nix store. Use `PasswordCmd` to read the credential at runtime."
  ];
}
