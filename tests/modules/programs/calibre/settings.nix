{
  programs.calibre = {
    enable = true;
    plugins = [
      ./plugins/a
      ./plugins/b
    ];
  };

  nmt.script = ''
    assertFileExists home-files/.config/calibre/plugins/a.zip
    assertFileExists home-files/.config/calibre/plugins/b.zip
  '';
}
