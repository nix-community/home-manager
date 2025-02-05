{
  programs.yt-dlp = {
    enable = true;
    extraConfig = ''
      --config-locations /home/user/.yt-dlp.conf
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/yt-dlp/config
    assertFileContent home-files/.config/yt-dlp/config ${
      ./yt-dlp-extraConfig-expected
    }
  '';
}
