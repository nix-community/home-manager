{
  programs.process-compose = {
    enable = true;
    settings = {
      theme = "Cobalt";
      sort = {
        by = "NAME";
        isReversed = false;
      };
      disable_exit_confirmation = false;
    };
    theme = {
      body = {
        fgColor = "white";
        bgColor = "black";
        secondaryTextColor = "yellow";
        tertiaryTextColor = "green";
        borderColor = "white";
      };
      stat_table = {
        keyFgColor = "yellow";
        valueFgColor = "white";
        logoColor = "yellow";
      };
      proc_table = {
        fgColor = "lightskyblue";
        fgWarning = "yellow";
        fgPending = "grey";
        fgCompleted = "lightgreen";
        fgError = "red";
        headerFgColor = "white";
      };
      help = {
        fgColor = "black";
        keyColor = "white";
        hlColor = "green";
        categoryFgColor = "lightskyblue";
      };
      dialog = {
        fgColor = "cadetblue";
        bgColor = "black";
        buttonFgColor = "black";
        buttonBgColor = "lightskyblue";
        buttonFocusFgColor = "black";
        buttonFocusBgColor = "dodgerblue";
        labelFgColor = "yellow";
        fieldFgColor = "black";
        fieldBgColor = "lightskyblue";
      };
    };
    shortcuts = {
      log_follow = {
        toggle_description = {
          false = "Follow Off";
          true = "Follow On";
        };
        shortcut = "F5";
      };
      log_screen = {
        toggle_description = {
          false = "Half Screen";
          true = "Full Screen";
        };
        shortcut = "F4";
      };
      log_wrap = {
        toggle_description = {
          false = "Wrap Off";
          true = "Wrap On";
        };
        shortcut = "F6";
      };
      process_restart = {
        description = "Restart";
        shortcut = "Ctrl-R";
      };
      process_screen = {
        toggle_description = {
          false = "Half Screen";
          true = "Full Screen";
        };
        shortcut = "F8";
      };
      process_start = {
        description = "Start";
        shortcut = "F7";
      };
      process_stop = {
        description = "Stop";
        shortcut = "F9";
      };
      quit = {
        description = "Quit";
        shortcut = "F10";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/process-compose/settings.yaml
    assertFileContent home-files/.config/process-compose/settings.yaml ${./expected-settings.yaml}

    assertFileExists home-files/.config/process-compose/theme.yaml
    assertFileContent home-files/.config/process-compose/theme.yaml ${./expected-theme.yaml}

    assertFileExists home-files/.config/process-compose/shortcuts.yaml
    assertFileContent home-files/.config/process-compose/shortcuts.yaml ${./expected-shortcuts.yaml}
  '';
}
