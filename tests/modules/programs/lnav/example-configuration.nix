{
  programs.lnav = {
    enable = true;
    settings = {
      ui = {
        theme = "monokai";
      };
    };
    formats = {
      custom = ./formats/custom.json;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/lnav/config.json
    assertFileContent home-files/.config/lnav/config.json \
      ${./example-configuration.json}

    assertFileExists home-files/.config/lnav/formats/installed/custom.json
    assertFileContent home-files/.config/lnav/formats/installed/custom.json \
      ${./formats/custom.json}
  '';
}
