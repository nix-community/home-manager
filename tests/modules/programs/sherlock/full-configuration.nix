{
  programs.sherlock = {
    enable = true;

    settings = {
      appearance = {
        width = 1000;
        height = 600;
        gsk_renderer = "cairo";
        icon_size = 32;
        opacity = 0.95;
      };

      caching = {
        enable = true;
      };

      default_apps = {
        browser = "firefox";
        calendar_client = "thunderbird";
        teams = "teams-for-linux --enable-features=UseOzonePlatform --ozone-platform=wayland --url {meeting_url}";
        terminal = "kitty";
      };

      search_bar_icon = {
        enable = true;
      };

      status_bar.enable = true;

      units = {
        lengths = "feet";
        weights = "lb";
        volumes = "oz";
        temperatures = "F";
        currency = "usd";
      };
    };

    launchers = [
      {
        name = "Weather";
        type = "weather";
        args = {
          location = "Appleton";
          update_interval = 60;
        };
        priority = 1;
        home = "OnlyHome";
        async = true;
        shortcut = false;
        spawn_focus = false;
      }
      {
        name = "App Launcher";
        alias = "app";
        type = "app_launcher";
        args = { };
        priority = 2;
        home = "Home";
      }
      {
        name = "Web Search";
        display_name = "DuckDuckGo Search";
        alias = "ddg";
        type = "web_launcher";
        tag_start = "{keyword}";
        tag_end = "{keyword}";
        args = {
          search_engine = "duckduckgo";
          icon = "duckduckgo";
        };
        priority = 100;
      }
      {
        name = "Calculator";
        type = "calculation";
        args = {
          capabilities = [
            "calc.math"
            "calc.units"
          ];
        };
        priority = 1;
      }
      {
        name = "Clipboard";
        type = "clipboard-execution";
        args = {
          capabilities = [
            "url"
            "colors.all"
            "calc.math"
            "calc.units"
          ];
        };
        priority = 1;
        home = "Home";
      }
      {
        name = "Nix Commands";
        alias = "nix";
        type = "command";
        args = {
          commands = {
            "Search Packages" = {
              icon = "nix-snowflake";
              exec = "firefox https://search.nixos.org/packages?query={keyword}";
              search_string = "packages;search;nixpkgs";
              tag_start = "search:";
              tag_end = "";
            };
            "Search Options" = {
              icon = "nix-snowflake";
              exec = "firefox https://search.nixos.org/options?query={keyword}";
              search_string = "options;config;nixos";
              tag_start = "options:";
              tag_end = "";
            };
            "NixOS Wiki" = {
              icon = "nix-snowflake";
              exec = "firefox https://wiki.nixos.org/w/index.php?search={keyword}";
              search_string = "wiki;docs;documentation";
              tag_start = "wiki:";
              tag_end = "";
            };
            "Nix Search TV" = {
              icon = "nix-snowflake";
              exec = "kitty -e nix-search-tv";
              search_string = "interactive;search;tv";
            };
          };
        };
        priority = 5;
      }
      {
        name = "Emoji Picker";
        type = "emoji_picker";
        args = {
          default_skin_tone = "Simpsons";
        };
        priority = 4;
        home = "Search";
      }
      {
        name = "Kill Process";
        alias = "kill";
        type = "process";
        args = { };
        priority = 6;
        home = "Search";
      }
    ];

    aliases = {
      "DuckDuckGo" = {
        name = "DuckDuckGo";
        icon = "duckduckgo";
        exec = "firefox https://duckduckgo.com/?q=%s";
        keywords = "search web ddg";
      };
    };

    ignore = ''
      hicolor-icon-theme.desktop
      user-dirs.desktop
      mimeinfo.cache.desktop
      org.freedesktop.IBus.Setup.desktop
      ca.desrt.dconf-editor.desktop
    '';

    style = ''
      window {
        background-color: #2E3440;
        border-radius: 8px;
      }
      entry {
        background-color: #3B4252;
        color: #ECEFF4;
      }
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.config/sherlock/config.toml
    assertFileContent home-files/.config/sherlock/config.toml ${./full-configuration.toml}

    assertFileExists home-files/.config/sherlock/sherlock_alias.json
    assertFileContent home-files/.config/sherlock/sherlock_alias.json ${./full-configuration-aliases.json}

    assertFileExists home-files/.config/sherlock/fallback.json
    assertFileContent home-files/.config/sherlock/fallback.json ${./full-configuration-fallback.json}

    assertFileExists home-files/.config/sherlock/sherlockignore
    assertFileContent home-files/.config/sherlock/sherlockignore ${./full-configuration-ignore}

    assertFileExists home-files/.config/sherlock/main.css
    assertFileContent home-files/.config/sherlock/main.css ${./full-configuration-style.css}
  '';
}
