{
  services.mpdris2 = {
    enable = true;
    settings = {
      Library.music_dir = "/music";
      Connection.password = null;
    };
  };

  nmt.script = ''
    configFile=home-files/.config/mpDris2/mpDris2.conf
    assertFileRegex "$configFile" 'music_dir = /music'
    assertFileNotRegex "$configFile" 'password ='
  '';
}
