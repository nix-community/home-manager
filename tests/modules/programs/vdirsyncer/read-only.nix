{
  programs.vdirsyncer.enable = true;

  accounts.calendar = {
    basePath = "/home/hm-user/calendars";
    accounts = {
      implicit = {
        vdirsyncer.enable = true;
        remote = {
          type = "http";
          url = "https://example.com/implicit.ics";
        };
      };

      readOnly = {
        vdirsyncer = {
          enable = true;
          localReadOnly = true;
        };
        remote = {
          type = "caldav";
          url = "https://example.com/calendars/";
        };
      };

      readWrite = {
        vdirsyncer = {
          enable = true;
          localReadOnly = false;
        };
        remote = {
          type = "http";
          url = "https://example.com/read-write.ics";
        };
      };
    };
  };

  nmt.script = ''
    assertFileContent home-files/.config/vdirsyncer/config ${./read-only.conf}
  '';
}
