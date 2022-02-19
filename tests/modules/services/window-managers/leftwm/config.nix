{ ... }: {
  config = {
    xsession.windowManager.leftwm = {
      enable = true;
      settings = {
        modkey = "Mod4";
        mousekey = "Mod4";
        workspaces = [ ];
        tags = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" ];
        layouts = [
          "MainAndVertStack"
          "MainAndHorizontalStack"
          "MainAndDeck"
          "GridHorizontal"
          "EvenHorizontal"
          "EvenVertical"
          "Fibonacci"
          "CenterMain"
          "CenterMainBalanced"
          "Monocle"
          "RightWiderLeftStack"
        ];
        layout_mode = "Workspace";
        scratchpad = [ ];
        disable_current_tag_swap = false;
        focus_behaviour = "Sloppy";
        focus_new_windows = true;
        keybind = [
          {
            command = "Execute";
            value = "dmenu_run";
            modifier = [ "modkey" ];
            key = "p";
          }
          {
            command = "Execute";
            value = "slock";
            modifier = [ "modkey" "Control" ];
            key = "l";
          }
          {
            command = "NextLayout";
            modifier = [ "modkey" "Control" ];
            key = "Up";
          }
          {
            command = "GotoTag";
            value = "1";
            modifier = [ "modkey" ];
            key = "1";
          }
        ];
      };
    };

    test.stubs.leftwm = { };

    nmt.script = ''
      config=home-files/.config/leftwm/config.toml
      assertFileExists "$config"
      assertFileContent "$config" ${./config-config.toml}
    '';
  };
}
