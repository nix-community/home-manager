{ lib, options, ... }:
{
  services.mpdris2 = {
    enable = true;
    mpd.musicDirectory = ./.;
    settings.Library.cover_regex = "^cover";
  };

  test.asserts.warnings.expected = [
    "The option `services.mpdris2.mpd.musicDirectory' defined in ${lib.showFiles options.services.mpdris2.mpd.musicDirectory.files} has been changed to `services.mpdris2.settings' that has a different type. Please read `services.mpdris2.settings' documentation and update your configuration accordingly."
  ];

  nmt.script = ''
    configFile=home-files/.config/mpDris2/mpDris2.conf
    assertFileRegex "$configFile" 'music_dir = ${toString ./.}'
    assertFileRegex "$configFile" 'cover_regex = \^cover'
  '';
}
