{ config, lib, pkgs, ... }:

{
  config = {
    programs.miniplayer = {
      enable = true;
      imageMethod = "ueberzug";
      mpd = {
        host = "localhost";
        port = 8123;
        pass = "example";
      };

      bindings = {
        ">" = "next_track";
        "<" = "last_track";
        "+" = "volume_up";
        "-" = "volume_down";
        "p" = "play_pause";
        "q" = "quit";
        "h" = "help";
        "i" = "toggle_info";
        "up" = "select_up";
        "down" = "select_down";
        "enter" = "select";
        "Up" = "move_up";
        "Down" = "move_down";
        "delete" = "delete";
        "x" = "shuffle";
        "r" = "repeat";
      };

      settings = {
        player = {
          font_width = 11;
          font_height = 24;
          volume_step = 5;
          auto_close = false;
          album_art_only = false;
          show_playlist = true;
        };
        theme = {
          accent_color = "auto";
          bar_color = "auto";
          time_color = "white";
          bar_body = "-";
          bar_head = ">";
        };
      };
    };

    test.stubs.miniplayerDummy = { };

    nmt.script = ''
      assertFileContent \
        home-files/.config/miniplayer/config \
        ${./miniplayer-expected-config}
    '';
  };
}
