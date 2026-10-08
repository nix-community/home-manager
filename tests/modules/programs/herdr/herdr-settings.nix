{
  xdg.enable = true;

  programs.herdr = {
    enable = true;

    settings = {
      onboarding = false;

      update = {
        channel = "stable";
        version_check = true;
        manifest_check = true;
      };

      terminal = {
        default_shell = "nu";
        shell_mode = "auto";
        new_cwd = "follow";
      };

      worktrees.directory = "~/.herdr/worktrees";

      remote.manage_ssh_config = true;

      theme = {
        name = "catppuccin";
        auto_switch = true;
        light_name = "catppuccin-latte";
        dark_name = "catppuccin";
        custom = {
          accent = "#a6e3a1";
          green = "#a6e3a1";
        };
      };

      ui = {
        sidebar_width = 32;
        sidebar_min_width = 18;
        sidebar_max_width = 36;
        mobile_width_threshold = 64;
        mouse_capture = true;
        confirm_close = true;
        agent_panel_sort = "priority";
        accent = "cyan";
        toast = {
          delivery = "herdr";
          delay_seconds = 1;
          herdr.position = "bottom-right";
          clipboard = {
            enabled = true;
            position = "bottom-center";
          };
        };
        sound = {
          enabled = true;
          path = "sounds/notification.mp3";
          agents = {
            droid = "off";
            claude = "on";
          };
        };
      };

      keys = {
        prefix = "ctrl+b";
        goto = "prefix+g";
        new_tab = "prefix+c";
        next_tab = [
          "prefix+n"
          "ctrl+alt+]"
        ];
        focus_pane_left = "prefix+h";
        split_horizontal = "prefix+minus";
        command = [
          {
            key = "prefix+alt+g";
            type = "pane";
            command = "lazygit";
            description = "run lazygit";
          }
          {
            key = "prefix+l";
            type = "plugin_action";
            command = "example.layout.apply";
            description = "apply layout";
          }
        ];
      };

      advanced.scrollback_limit_bytes = 10485760;

      experimental = {
        pane_history = true;
        allow_nested = false;
        kitty_graphics = false;
        reveal_hidden_cursor_for_cjk_ime = false;
        cjk_ime_agents = [ ];
        cjk_ime_cursor_shape = "steady_block";
      };

      session.resume_agents_on_restore = true;
    };
  };

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertFileExists "home-files/.config/herdr/config.toml"
    assertFileContent \
      "home-files/.config/herdr/config.toml" \
      ${./settings-expected.toml}
  '';
}
