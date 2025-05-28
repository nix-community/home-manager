{ ... }:
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
    assertFileContent \
       home-files/.config/jellyfin-mpv-shim/conf.json \
       ${./jellyfin-mpv-shim-example-settings-expected-settings}
    assertFileContent \
       home-files/.config/jellyfin-mpv-shim/mpv.conf \
       ${./jellyfin-mpv-shim-example-settings-expected-config}
    assertFileContent \
       home-files/.config/jellyfin-mpv-shim/input.conf \
       ${./jellyfin-mpv-shim-example-settings-expected-bindings}
  '';
}
