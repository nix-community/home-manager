{
  services.jellyfin-mpv-shim = {
    enable = true;

    settings = {
      allow_transcode_to_h265 = false;
      always_transcode = false;
      audio_output = "hdmi";
      auto_play = true;
      fullscreen = true;
      player_name = "mpv-shim";
    };

    mpvBindings = {
      WHEEL_UP = "seek 10";
      WHEEL_DOWN = "seek -10";
      "Alt+0" = "set window-scale 0.5";
    };

    mpvConfig = {
      force-window = true;
      ytdl-format = "bestvideo+bestaudio";
      cache-default = 4000000;
    };
  };

  nmt.script = ''
    # FIXME:
    # assertFileContent \
    #    home-files/.config/jellyfin-mpv-shim/conf.json \
    #    ${./example-settings-expected-settings}
    assertFileContent \
       home-files/.config/jellyfin-mpv-shim/mpv.conf \
       ${./example-settings-expected-config}
    assertFileContent \
       home-files/.config/jellyfin-mpv-shim/input.conf \
       ${./example-settings-expected-bindings}
  '';
}
