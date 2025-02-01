{
  config = {
    programs.clock-rs = {
      enable = true;
      settings = {
        general = {
          color = "magenta";
          interval = 250;
          blink = true;
          bold = true;
        };

        position = {
          horizontal = "start";
          vertical = "end";
        };

        date = {
          fmt = "%A, %B %d, %Y";
          use_12h = true;
          utc = true;
          hide_seconds = true;
        };
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/clock-rs/conf.toml
      assertFileContent home-files/.config/clock-rs/conf.toml \
          ${./example-settings-expected.toml}
    '';
  };
}
