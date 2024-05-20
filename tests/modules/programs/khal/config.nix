{ ... }:

{
  programs.khal = {
    enable = true;
    settings = {
      default.timedelta = "5d";
      view.agenda_event_format =
        "{calendar-color}{cancelled}{start-end-time-style} {title}{repeat-symbol}{reset}";
    };

  };
  accounts.calendar = {
    basePath = "$XDG_CONFIG_HOME/cal";
    accounts = {
      test = {
        primary = true;
        primaryCollection = "test";
        khal = {
          enable = true;
          readOnly = true;
          color = "#ff0000";
          type = "calendar";
        };
        local.type = "filesystem";
        local.fileExt = ".ics";
        name = "test";
        remote = {
          type = "http";
          url = "https://example.com/events.ical";
        };
      };
      testWithAddresss = {
        khal = {
          enable = true;
          addresses = [ "john.doe@email.com" ];
        };
        local = {
          type = "filesystem";
          fileExt = ".ics";
        };
        remote = {
          type = "http";
          url = "https://example.com/events.ical";
        };
      };
      testWithMultipleAddresss = {
        khal = {
          enable = true;
          addresses = [ "john.doe@email.com" "another.brick@on.the.wall" ];
        };
        local = {
          type = "filesystem";
          fileExt = ".ics";
        };
        remote = {
          type = "http";
          url = "https://example.com/events.ical";
        };
      };
    };
  };

  accounts.contact = {
    basePath = "$XDG_CONFIG_HOME/card";
    accounts = {
      testcontacts = {
        khal = {
          enable = true;
          collections = [ "default" "automaticallyCollected" ];
        };
        local.type = "filesystem";
        local.fileExt = ".vcf";
        name = "testcontacts";
        remote = {
          type = "http";
          url = "https://example.com/contacts.vcf";
        };
      };

      testcontactsNoCollections = {
        khal.enable = true;
        local.type = "filesystem";
        local.fileExt = ".vcf";
        name = "testcontactsNoCollections";
        remote = {
          type = "http";
          url = "https://example.com/contacts.vcf";
        };
      };
    };
  };

  test.stubs = { khal = { }; };

  nmt.script = ''
    configFile=home-files/.config/khal/config
    assertFileExists $configFile
    assertFileContent $configFile ${./khal-config-expected}
  '';
}
