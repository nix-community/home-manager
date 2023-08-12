{ pkgs, lib, ... }:

{
  programs.qcal.enable = true;
  accounts.calendar.accounts = {
    http-test = {
      remote = { url = "https://example.com/events.ical"; };
      qcal.enable = true;
    };
    webdav-test = {
      remote = {
        url = "https://cal.example.com/anton/work";
        userName = "anton";
        passwordCommand = [ "pass" "show" "calendar" ];
      };
      qcal.enable = true;
    };
  };

  test.stubs = { qcal = { }; };

  nmt.script = ''
    assertFileExists home-files/.config/qcal/config.json
    assertFileContent home-files/.config/qcal/config.json ${
      ./mixed.json-expected
    }
  '';
}
