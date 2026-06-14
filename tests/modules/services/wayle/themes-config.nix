{ config, ... }:
{
  services.wayle = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "wayle"; };

    settings = {
      styling = {
        theme-provider = "wayle";
      };

      bar.location = "top";
    };

    themes.tokyo-night = ''
      bg = "#1a1b26"
      surface = "#24283b"
      fg = "#c0caf5"
      fg_muted = "#9aa5ce"
      primary = "#7aa2f7"
      red = "#f7768e"
      yellow = "#e0af68"
      green = "#9ece6a"
      blue = "#7aa2f7"
    '';
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/wayle/themes/tokyo-night.toml \
      ${./themes-config-expected.toml}
  '';
}
