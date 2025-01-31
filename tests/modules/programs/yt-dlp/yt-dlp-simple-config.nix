{
  programs.yt-dlp = {
    enable = true;
    settings = {
      embed-thumbnail = true;
      embed-subs = false;
      sub-langs = "all";
      downloader = "aria2c";
      downloader-args = "aria2c:'-c -x8 -s8 -k1M'";
      trim-filenames = 30;
    };
    extraConfig = ''
      --config-locations /home/user/.yt-dlp.conf
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/yt-dlp/config
    assertFileContent home-files/.config/yt-dlp/config ${
      ./yt-dlp-simple-config-expected
    }
  '';
}
