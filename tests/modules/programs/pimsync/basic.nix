{
  accounts.calendar = {
    accounts.mine = {
      pimsync.enable = true;
      remote = {
        passwordCommand = [
          "pass"
          "caldav"
        ];
        type = "caldav";
        url = "https://caldav.example.com";
        userName = "alice";
      };
    };
    accounts.http = {
      pimsync.enable = true;
      remote = {
        type = "http";
        url = "https://example.com/calendar";
      };
    };
    basePath = ".local/state/calendar";
  };

  accounts.contact = {
    accounts.mine = {
      pimsync.enable = true;
      remote = {
        passwordCommand = [
          "pass"
          "carddav"
        ];
        type = "carddav";
        url = "https://carddav.example.com";
        userName = "bob";
      };
    };
    basePath = ".local/state/contact";
  };

  programs.pimsync = {
    enable = true;
    settings = [
      {
        name = "status_path";
        params = [ "/test/dir" ];
      }
    ];
  };

  test.stubs.systemd.outPath = null;

  nmt.script = ''
    assertFileExists home-files/.config/pimsync/pimsync.conf
    assertFileContent home-files/.config/pimsync/pimsync.conf ${./basic.scfg}
  '';
}
