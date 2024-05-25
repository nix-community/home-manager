{
  programs.spotify-player = {
    enable = true;

    settings = {
      theme = "default";
      playback_window_position = "Top";
      copy_command = {
        command = "wl-copy";
        args = [ ];
      };
      device = {
        audio_cache = false;
        normalization = false;
      };
    };

    themes = [{
      name = "default2";
      palette = {
        black = "black";
        red = "red";
        green = "green";
        yellow = "yellow";
        blue = "blue";
        magenta = "magenta";
        cyan = "cyan";
        white = "white";
        bright_black = "bright_black";
        bright_red = "bright_red";
        bright_green = "bright_green";
        bright_yellow = "bright_yellow";
        bright_blue = "bright_blue";
        bright_magenta = "bright_magenta";
        bright_cyan = "bright_cyan";
        bright_white = "bright_white";
      };
      component_style = {
        block_title = { fg = "Magenta"; };
        border = { };
        playback_track = {
          fg = "Cyan";
          modifiers = [ "Bold" ];
        };
        playback_artists = {
          fg = "Cyan";
          modifiers = [ "Bold" ];
        };
        playback_album = { fg = "Yellow"; };
        playback_metadata = { fg = "BrightBlack"; };
        playback_progress_bar = {
          bg = "BrightBlack";
          fg = "Green";
        };
        current_playing = {
          fg = "Green";
          modifiers = [ "Bold" ];
        };
        page_desc = {
          fg = "Cyan";
          modifiers = [ "Bold" ];
        };
        table_header = { fg = "Blue"; };
        selection = { modifiers = [ "Bold" "Reversed" ]; };
      };
    }];

    keymaps = [
      {
        command = "NextTrack";
        key_sequence = "g n";
      }
      {
        command = "PreviousTrack";
        key_sequence = "g p";
      }
      {
        command = "Search";
        key_sequence = "C-c C-x /";
      }
      {
        command = "ResumePause";
        key_sequence = "M-enter";
      }
      {
        command = "None";
        key_sequence = "q";
      }
    ];
  };

  test.stubs.spotify-player = { };

  nmt.script = ''
    assertFileContent home-files/.config/spotify-player/app.toml ${./app.toml}
    assertFileContent home-files/.config/spotify-player/theme.toml ${
      ./theme.toml
    }
    assertFileContent home-files/.config/spotify-player/keymap.toml ${
      ./keymap.toml
    }
  '';
}
