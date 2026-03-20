{
  programs.asciinema = {
    enable = true;

    settings = {
      server.url = "https://asciinema.example.com";

      session = {
        command = "/run/current-system/sw/bin/bash -l";
        capture_input = true;
        capture_env = "SHELL,TERM,USER";
        idle_time_limit = 2;
        pause_key = "^p";
        add_marker_key = "^x";
        prefix_key = "^a";
      };

      playback = {
        speed = 2;
        pause_key = "^p";
        step_key = "s";
        next_marker_key = "m";
      };

      notifications = {
        enable = false;
        command = ''tmux display-message "$TEXT"'';
      };
    };
  };

  ## TODO: check that `command` quote escaping doesn't break things
  nmt.script = ''
    assertFileExists home-files/.config/asciinema/config.toml
    assertFileContent home-files/.config/asciinema/config.toml \
    ${builtins.toFile "expected.asciinema_config.toml" ''
      [notifications]
      command = "tmux display-message \"$TEXT\""
      enable = false

      [playback]
      next_marker_key = "m"
      pause_key = "^p"
      speed = 2
      step_key = "s"

      [server]
      url = "https://asciinema.example.com"

      [session]
      add_marker_key = "^x"
      capture_env = "SHELL,TERM,USER"
      capture_input = true
      command = "/run/current-system/sw/bin/bash -l"
      idle_time_limit = 2
      pause_key = "^p"
      prefix_key = "^a"
    ''}
  '';
}
