{
  programs.sioyek = {
    enable = true;
    bindings = {
      "move_down" = "j";
      "move_left" = "h";
      "move_right" = "l";
      "move_up" = "k";
      "screen_down" = [ "d" "<C-d>" ];
      "screen_up" = [ "u" "<C-u>" ];
    };
    config = {
      "dark_mode_background_color" = "0.0 0.0 0.0";
      "dark_mode_contrast" = "0.8";
    };
  };

  nmt = {
    description = "Sioyek basic setup with sample configuration";
    script = ''
      assertFileExists home-files/.config/sioyek/prefs_user.config
      assertFileContent home-files/.config/sioyek/prefs_user.config ${
        ./test_prefs_user.config
      }

      assertFileExists home-files/.config/sioyek/keys_user.config
      assertFileContent home-files/.config/sioyek/keys_user.config ${
        ./test_keys_user.config
      }
    '';
  };
}
