{
  programs.ncmpcpp.enable = true;

  services.mpd.enable = true;
  services.mpd.musicDirectory = "/home/user/music";

  nmt.script = ''
    assertFileContent \
      home-files/.config/ncmpcpp/config \
      ${./ncmpcpp-use-mpd-config-expected-config}

    assertPathNotExists home-files/.config/ncmpcpp/bindings
  '';
}
