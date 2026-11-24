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

    themes = {
      "example-theme" = ''
        (
            default_album_art_path: None,
            format_tag_separator: " | ",
            browser_column_widths: [20, 38, 42],
            background_color: None,
            symbols: (
                song: "S",
                dir: "D",
                playlist: "P",
                marker: "M",
                ellipsis: "...",
                song_style: None,
                dir_style: None,
                playlist_style: None,
            ),
        )
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/rmpc/config.ron
    assertFileContent home-files/.config/rmpc/config.ron \
    ${./example-config.ron}

    assertFileExists home-files/.config/rmpc/themes/example-theme.ron
    assertFileContent home-files/.config/rmpc/themes/example-theme.ron \
    ${./example-theme.ron}
  '';
}
