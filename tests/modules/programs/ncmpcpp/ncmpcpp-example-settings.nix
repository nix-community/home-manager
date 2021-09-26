{ pkgs, ... }:

{
  config = {
    programs.ncmpcpp = {
      enable = true;
      mpdMusicDir = "/home/user/music";

      settings = {
        user_interface = "alternative";
        display_volume_level = false;
        playlist_disable_highlight_delay = 0;
      };

      bindings = [
        {
          key = "j";
          command = "scroll_down";
        }
        {
          key = "k";
          command = "scroll_up";
        }
        {
          key = "J";
          command = [ "select_item" "scroll_down" ];
        }
        {
          key = "K";
          command = [ "select_item" "scroll_up" ];
        }
        {
          key = "x";
          command = "delete_playlist_items";
        }
        {
          key = "x";
          command = "delete_browser_items";
        }
        {
          key = "x";
          command = "delete_stored_playlist";
        }
      ];
    };

    test.stubs.ncmpcpp = { };

    nmt.script = ''
      assertFileContent \
        home-files/.config/ncmpcpp/config \
        ${./ncmpcpp-example-settings-expected-config}

      assertFileContent \
        home-files/.config/ncmpcpp/bindings \
        ${./ncmpcpp-example-settings-expected-bindings}
    '';
  };
}
