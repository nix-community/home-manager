{ ... }:

{
  programs.yazi = {
    enable = true;

    keymap = {
      input.prepend_keymap = [
        {
          run = "close";
          on = [ "<C-q>" ];
        }
        {
          run = "close --submit";
          on = [ "<Enter>" ];
        }
        {
          run = "escape";
          on = [ "<Esc>" ];
        }
        {
          run = "backspace";
          on = [ "<Backspace>" ];
        }
      ];
      manager.prepend_keymap = [
        {
          run = "escape";
          on = [ "<Esc>" ];
        }
        {
          run = "quit";
          on = [ "q" ];
        }
        {
          run = "close";
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
