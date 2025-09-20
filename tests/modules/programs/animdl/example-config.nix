{
  programs.animdl = {
    enable = true;
    settings = {
      default_provider = "animixplay";
      site_urls.animixplay = "https://www.animixplay.to/";
      quality_string = "best[subtitle]/best";
      default_player = "mpv";
      ffmpeg = {
        executable = "ffmpeg";
        hls_download = false;
        submerge = true;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/animdl/config.yml
    assertFileContent home-files/.config/animdl/config.yml \
      ${./config.yml}
  '';
}
