{ ... }:

{
  programs.khal.enable = true;
  accounts.calendar = {
    basePath = "$XDG_CONFIG_HOME/cal";
    accounts = {
      test = {
        primary = true;
        primaryCollection = "test";
        khal = {
          enable = true;
          readOnly = true;
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
    };
  };

  test.stubs = { khal = { }; };

  nmt.script = ''
    assertFileExists home-files/.config/khal/config
  '';
}
