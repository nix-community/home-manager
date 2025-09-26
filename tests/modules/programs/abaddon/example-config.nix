{
  programs.abaddon = {
    enable = true;
    settings = {
      windows.hideconsole = true;
      notifications.enabled = false;
      discord = {
        token = "MZ1yGvKTjE0rY0cV8i47CjAa.uRHQPq.Xb1Mk2nEhe-4iUcrGOuegj57zMC";
        autoconnect = true;
      };

      gui = {
        stock_emojis = false;
        animations = false;
        alt_menu = true;
        hide_to_tray = true;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/abaddon/abaddon.ini
    assertFileContent home-files/.config/abaddon/abaddon.ini \
      ${./abaddon.ini}
  '';
}
