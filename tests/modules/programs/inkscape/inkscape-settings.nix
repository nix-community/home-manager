{
  programs.inkscape = {
    enable = true;
    settings = {
      ui = {
        "@iconset" = "multicolor";
        "@theme" = "Adwaita";
      };
      snap = {
        "@global" = 1;
      };
    };
  };

  nmt.script = ''
    prefsFile=home-files/.config/inkscape/preferences.xml

    assertFileExists "$prefsFile"
    assertFileContent "$prefsFile" "${./preferences.xml}"
  '';
}
