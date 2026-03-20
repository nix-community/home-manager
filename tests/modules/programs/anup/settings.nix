{
  programs.anup = {
    enable = true;
    config = ''
      (
          series_dir: "/home/matteo/anime",
          reset_dates_on_rewatch: false,
          episode: (
              percent_watched_to_progress: (50.0),
              player: "mpv",
              player_args: [],
          ),
          tui: (
              keys: (
                  play_next_episode: "enter",
              ),
          ),
      )
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/anup/config.ron
    assertFileContent home-files/.config/anup/config.ron \
      ${./config.ron}
  '';
}
