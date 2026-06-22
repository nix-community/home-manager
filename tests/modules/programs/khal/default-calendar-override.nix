{
  programs.khal = {
    enable = true;
    settings.default.default_calendar = "private";
  };

  accounts.calendar = {
    basePath = "$XDG_CONFIG_HOME/cal";
    accounts = {
      google = {
        primary = true;
        primaryCollection = "google";
        khal.enable = true;
        local = {
          type = "filesystem";
          fileExt = ".ics";
        };
        remote = {
          type = "http";
          url = "https://example.com/google.ics";
        };
      };

      private = {
        khal.enable = true;
        local = {
          type = "filesystem";
          fileExt = ".ics";
        };
        remote = {
          type = "http";
          url = "https://example.com/private.ics";
        };
      };
    };
  };

  nmt.script = ''
    configFile=home-files/.config/khal/config
    assertFileExists $configFile
    assertFileRegex $configFile "^default_calendar=private$"
    assertFileRegex $configFile "^highlight_event_days=true$"
  '';
}
