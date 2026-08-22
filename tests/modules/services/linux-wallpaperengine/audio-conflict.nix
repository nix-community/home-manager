{ lib, options, ... }:
{
  services.linux-wallpaperengine = {
    enable = true;
    audio = {
      silent = true;
      volume = 50;
    };
  };

  test.asserts.assertions.expected = [
    ''
      services.linux-wallpaperengine.audio.silent and services.linux-wallpaperengine.audio.volume cannot be set together.

      Definitions:
        services.linux-wallpaperengine.audio.silent defined in ${lib.showFiles options.services.linux-wallpaperengine.audio.silent.files}
        services.linux-wallpaperengine.audio.volume defined in ${lib.showFiles options.services.linux-wallpaperengine.audio.volume.files}
    ''
  ];
}
