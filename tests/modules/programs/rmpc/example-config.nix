{
  programs.rmpc = {
    enable = true;
    config = ''
      (
          address: "127.0.0.1:6600",
          password: None,
          theme: None,
          cache_dir: None,
          on_song_change: None,
          volume_step: 5,
          max_fps: 30,
          scrolloff: 0,
          wrap_navigation: false,
          enable_mouse: true,
          enable_config_hot_reload: true,
          status_update_interval_ms: 1000,
          select_current_song_on_change: false,
          browser_song_sort: [Disc, Track, Artist, Title],
      )
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/rmpc/config.ron
    assertFileContent home-files/.config/rmpc/config.ron \
    ${./example-config.ron}
  '';
}
