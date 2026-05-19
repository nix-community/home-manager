{
  services.linux-wallpaperengine = {
    enable = true;
    wallpapers = [
      {
        monitor = "DP-1";
        wallpaper = "12345678";
        audio = {
          processing = false;
        };
      }
      {
        wallpaper = "12345678";
        monitor = "DP-2";
        fps = 30;
      }
    ];
  };

  test.asserts.assertions.expected = [
    ''
      The option definition `services.linux-wallpaperengine.wallpapers.*.audio' no longer has any effect; please remove it.
      Set `services.linux-wallpaperengine.audio' instead.
    ''
    ''
      The option definition `services.linux-wallpaperengine.wallpapers.*.fps' no longer has any effect; please remove it.
      Set `services.linux-wallpaperengine.fps' instead.
    ''
  ];
}
