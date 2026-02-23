{ config, ... }:
{
  xdg.enable = true;
  home.preferXdgDirectories = true;

  programs.w3m = {
    enable = true;
    package = null;
    bindings = {
      "UP" = "UP";
      "DOWN" = "DOWN";
      "LEFT" = "LEFT";
      "RIGHT" = "RIGHT";
      "o" = "GOTO";
    };
    bookmarks = {
      title = "links";
      marks = {
        category1 = [
          {
            name = "home-manager manual";
            url = "https://nix-community.github.io/home-manager/index.xhtml";
          }
        ];
        category2 = [
          {
            name = "nixos manual";
            url = "https://nixos.org/manual/nixos/stable/";
          }
        ];
      };
    };
    cgiBin = {
      "script.cgi".text = ''
        echo "watch the film Paprika"
      '';
    };
    settings = {
      display_column_number = 1;
      decode_url = 1;
      active_style = 1;
      graphic_char = 1;
      extbrowser = "firefox";
    };
    siteconf = [
      {
        url = "m!^https://duckduckgo.com/!i";
        preferences = [
          "url_charset utf-8"
          ''substitute_url "https://lite.duckduckgo.com"''
        ];
      }
    ];
    urimethodmap = {
      ddg = "file:/cgi-bin/search.cgi?%s";
      google = "file:/cgi-bin/search.cgi?%s";
    };
  };

  nmt.script = ''
    assertFileExists "home-files/.config/w3m/keymap"
    assertFileContent "home-files/.config/w3m/keymap" ${./expected-keymap}

    assertFileExists "home-files/.config/w3m/bookmark.html"
    assertFileContent "home-files/.config/w3m/bookmark.html" ${./expected-bookmark.html}

    assertFileExists "home-files/.config/w3m/cgi-bin/script.cgi"
    assertFileContains "home-files/.config/w3m/cgi-bin/script.cgi" "echo \"watch the film Paprika\""

    assertFileExists "home-files/.config/w3m/config"
    assertFileContent "home-files/.config/w3m/config" ${./expected-config}

    assertFileExists "home-files/.config/w3m/siteconf"
    assertFileContent "home-files/.config/w3m/siteconf" ${./expected-siteconf}

    assertFileExists "home-files/.config/w3m/urimethodmap"
    assertFileContent "home-files/.config/w3m/urimethodmap" ${./expected-urimethodmap}

    assertFileExists "home-files/.config/w3m/keymap"
    assertFileContent "home-files/.config/w3m/keymap" ${./expected-keymap}
  '';
}
