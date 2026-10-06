enable:
{ lib, ... }:
{
  accounts.calendar = {
    basePath = "calendars";
    accounts = {
      personal.noctalia.enable = enable;
      work = {
        noctalia.enable = enable;
        local.path = "/srv/calendars/work";
      };
      disabled = { };
      single = {
        noctalia.enable = enable;
        local = {
          type = "singlefile";
          path = "/srv/calendars/single.ics";
        };
      };
    };
  };

  programs.noctalia = {
    enable = true;
    package = null;
    settings = lib.mkIf enable {
      calendar = {
        refresh_minutes = 30;
        account.work = {
          name = "Work calendar";
          color = "#abcdef";
        };
      };
    };
  };

  nmt.script =
    if enable then
      ''
        assertFileContent home-files/.config/noctalia/config.toml ${./expected-calendars.toml}
      ''
    else
      ''
        assertPathNotExists home-files/.config/noctalia/config.toml
      '';
}
