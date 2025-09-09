{
  accounts.calendar = {
    accounts.caldav = {
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

  programs.pimsync = {
    enable = true;
    settings = [
      {
        name = "status_path";
        params = [ "/test/dir" ];
      }
    ];
  };

  nmt.script = ''
    assertFileExists home-files/.config/pimsync/pimsync.conf
    assertFileContent home-files/.config/pimsync/pimsync.conf ${./basic.scfg}
  '';
}
