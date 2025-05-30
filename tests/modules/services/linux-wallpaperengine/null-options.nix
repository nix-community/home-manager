{
  services.linux-wallpaperengine = {
    enable = true;
  };

  nmt.script = ''
    assertFileContent \
        home-files/.config/systemd/user/linux-wallpaperengine.service \
        ${./null-options-expected.service}
  '';
}
