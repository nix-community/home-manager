{
  programs.waveterm = {
    enable = true;
    settings = {
      "app:dismissarchitecturewarning" = false;
      "autoupdate:enabled" = false;
      "term:fontsize" = 12.0;
      "term:fontfamily" = "JuliaMono";
      "term:theme" = "my-custom-theme";
      "term:transparency" = 0.5;
      "window:showhelp" = false;
      "window:blur" = true;
      "window:opacity" = 0.5;
      "window:bgcolor" = "#000000";
      "window:reducedmotion" = true;
    };

    themes = {
      default-dark = {
        "display:name" = "Default Dark";
        "display:order" = 1;
        black = "#757575";
        red = "#cc685c";
        green = "#76c266";
        yellow = "#cbca9b";
        blue = "#85aacb";
        magenta = "#cc72ca";
        cyan = "#74a7cb";
        white = "#c1c1c1";
        brightBlack = "#727272";
        brightRed = "#cc9d97";
        brightGreen = "#a3dd97";
        brightYellow = "#cbcaaa";
        brightBlue = "#9ab6cb";
        brightMagenta = "#cc8ecb";
        brightCyan = "#b7b8cb";
        brightWhite = "#f0f0f0";
        gray = "#8b918a";
        cmdtext = "#f0f0f0";
        foreground = "#c1c1c1";
        selectionBackground = "";
        background = "#00000077";
        cursorAccent = "";
      };
    };

    bookmarks = {
      "bookmark@google" = {
        url = "https://www.google.com";
        title = "Google";
      };
      "bookmark@claude" = {
        url = "https://claude.ai";
        title = "Claude";
      };
      "bookmark@github" = {
        url = "https://github.com";
        title = "GitHub";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/waveterm/settings.json
    assertFileExists home-files/.config/waveterm/bookmarks.json
    assertFileExists home-files/.config/waveterm/termthemes.json

    assertFileContent home-files/.config/waveterm/settings.json \
    ${./cfg/settings.json}

    assertFileContent home-files/.config/waveterm/bookmarks.json \
    ${./cfg/bookmarks.json}

    assertFileContent home-files/.config/waveterm/termthemes.json \
    ${./cfg/termthemes.json}

  '';
}
