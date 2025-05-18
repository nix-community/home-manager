{ pkgs, ... }:
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

    nmt.script =
      let
        configDir =
          if pkgs.stdenv.isDarwin then
            "home-files/Library/Application Support/clock-rs"
          else
            "home-files/.config/clock-rs";
      in
      ''
        assertFileExists "${configDir}/conf.toml"
        assertFileContent "${configDir}/conf.toml" \
            ${./example-settings-expected.toml}
      '';
  };
}
