{
  programs.anvil-editor = {
    enable = true;
    settings = {
      general.exec = [
        "aad"
        "ado"
      ];
      layout.column-tag = "New Cut Paste Snarf Zerox Delcol";
      typesetting.replace-cr-with-tofu = false;
      env = {
        FOO = "BAR";
        BAR = "FOO";
      };
    };

    style = {
      TagFgColor = "#fefefe";
      TagBgColor = "#263859";
      BodyBgColor = "#17223b";
      ScrollFgColor = "#17223b";
      ScrollBgColor = "#6b778d";
      GutterWidth = 14;
      WinBorderColor = "#000000";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.anvil/settings.toml
    assertFileExists home-files/.anvil/style.js

    assertFileContent home-files/.anvil/settings.toml \
      ${./settings.toml}
    assertFileContent home-files/.anvil/style.js \
      ${./style.js}
  '';
}
