{ ... }:

{
  programs.yazi = {
    enable = true;

    keymap = {
      input.keymap = [
        {
          exec = "close";
          on = [ "<C-q>" ];
        }
        {
          exec = "close --submit";
          on = [ "<Enter>" ];
        }
        {
          exec = "escape";
          on = [ "<Esc>" ];
        }
        {
          exec = "backspace";
          on = [ "<Backspace>" ];
        }
      ];
      manager.keymap = [
        {
          exec = "escape";
          on = [ "<Esc>" ];
        }
        {
          exec = "quit";
          on = [ "q" ];
        }
        {
          exec = "close";
          on = [ "<C-q>" ];
        }
      ];
    };
    settings = {
      log = { enabled = false; };
      manager = {
        show_hidden = false;
        sort_by = "modified";
        sort_dir_first = true;
        sort_reverse = true;
      };
    };
    theme = {
      filetype = {
        rules = [
          {
            fg = "#7AD9E5";
            mime = "image/*";
          }
          {
            fg = "#F3D398";
            mime = "video/*";
          }
          {
            fg = "#F3D398";
            mime = "audio/*";
          }
          {
            fg = "#CD9EFC";
            mime = "application/x-bzip";
          }
        ];
      };
    };
    initLua = ./init.lua;
    plugins = {
      testplugin = ./plugin;
      ## Produces warning
      #"plugin-with-suffix.yazi" = ./plugin;
      ## Fails assertion
      #single-file-plugin = ./plugin/init.lua;
      #empty-dir-plugin = ./empty;
    };
    flavors = {
      testflavor = ./flavor;
      ## Produces warning
      #"flavor-with-suffix.yazi" = ./flavor;
      ## Fails assertion
      #single-file-flavor = ./flavor/flavor.toml;
      #empty-dir-flavor = ./empty;
    };
  };

  test.stubs.yazi = { };

  nmt.script = ''
    assertFileContent home-files/.config/yazi/keymap.toml \
      ${./keymap-expected.toml}
    assertFileContent home-files/.config/yazi/yazi.toml \
      ${./settings-expected.toml}
    assertFileContent home-files/.config/yazi/theme.toml \
      ${./theme-expected.toml}
    assertFileContent home-files/.config/yazi/init.lua \
      ${./init.lua}
    assertFileContent home-files/.config/yazi/plugins/testplugin.yazi/init.lua \
      ${./plugin/init.lua}
    assertFileContent home-files/.config/yazi/flavors/testflavor.yazi/flavor.toml \
      ${./flavor/flavor.toml}
  '';
}
