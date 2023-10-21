{ pkgs, lib, ... }:

{
  programs.qcal.enable = true;
  accounts.calendar.accounts.test = {
    qcal.enable = true;
    remote = { url = "https://example.com/events.ical"; };
  };

  test.stubs = { qcal = { }; };

  nmt.script = ''
    assertFileExists home-files/.config/qcal/config.json
    assertFileContent home-files/.config/qcal/config.json ${
      ./http-calendar.json-expected
    }
  '';
}
