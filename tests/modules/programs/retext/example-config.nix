{
  programs.retext = {
    enable = true;
    settings = {
      General = {
        documentStatsEnabled = true;
        lineNumbersEnabled = true;
        relativeLineNumbers = true;
        useWebEngine = true;
      };

      ColorScheme = {
        htmlTags = "green";
        htmlSymbols = "#ff8800";
        htmlComments = "#abc";
      };
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.config/ReText Project/ReText.conf"
    assertFileContent "home-files/.config/ReText Project/ReText.conf" \
      ${./ReText.conf}
  '';
}
