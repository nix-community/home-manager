{
  programs.radio-cli = {
    enable = true;
    settings = {
      config_version = "2.3.0";
      max_lines = 7;
      country = "ES";
      data = [
        {
          station = "lofi";
          url = "https://www.youtube.com/live/jfKfPfyJRdk?si=WDl-XdfuhxBfe6XN";
        }
      ];
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/radio-cli/config.json
    assertFileContent home-files/.config/radio-cli/config.json \
    ${./config.json}
  '';
}
