{
  programs.onlyoffice = {
    enable = true;
    settings = {
      UITheme = "theme-contrast-dark";
      editorWindowMode = false;
      forcedRtl = false;
      locale = "es-ES";
      maximized = true;
      position = "@Rect(100 56 1266 668)";
      titlebar = "custom";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/onlyoffice/DesktopEditors.conf
    assertFileContent home-files/.config/onlyoffice/DesktopEditors.conf \
    ${./example-config.conf}
  '';
}
