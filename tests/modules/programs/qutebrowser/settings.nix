{ pkgs, ... }:

{
  programs.qutebrowser = {
    enable = true;

    settings = {
      colors = {
        hints = {
          bg = "#000000";
          fg = "#ffffff";
        };
        tabs.bar.bg = "#000000";
      };
      spellcheck.languages = [ "en-US" "sv-SE" ];
      tabs.tabs_are_windows = true;
      tabs.padding = {
        __isDict = true;
        bottom = 1;
        left = 5;
        right = 5;
        top = 1;
      };
    };

    searchEngines = {
      DEFAULT = "https://duckduckgo.com/?q={}";

      # Nix stuff
      nix-home-manager =
        "https://home-manager-options.extranix.com/?query={}&release=master";
      nix-options =
        "https://search.nixos.org/options?channel=unstable&type=packages&query={}";
      nix-packages =
        "https://search.nixos.org/packages?channel=unstable&type=packages&query={}";
    };

    extraConfig = ''
      # Extra qutebrowser configuration.
    '';
  };

  test.stubs.qutebrowser = { };

  nmt.script = let
    qutebrowserConfig = if pkgs.stdenv.hostPlatform.isDarwin then
      ".qutebrowser/config.py"
    else
      ".config/qutebrowser/config.py";
  in ''
    assertFileContent \
      home-files/${qutebrowserConfig} \
      ${
        pkgs.writeText "qutebrowser-expected-config.py" ''
          config.load_autoconfig(False)
          c.colors.hints.bg = "#000000"
          c.colors.hints.fg = "#ffffff"
          c.colors.tabs.bar.bg = "#000000"
          c.spellcheck.languages = ["en-US", "sv-SE"]
          c.tabs.padding['bottom'] = 1
          c.tabs.padding['left'] = 5
          c.tabs.padding['right'] = 5
          c.tabs.padding['top'] = 1
          c.tabs.tabs_are_windows = True
          c.url.searchengines['DEFAULT'] = "https://duckduckgo.com/?q={}"
          c.url.searchengines['nix-home-manager'] = "https://home-manager-options.extranix.com/?query={}&release=master"
          c.url.searchengines['nix-options'] = "https://search.nixos.org/options?channel=unstable&type=packages&query={}"
          c.url.searchengines['nix-packages'] = "https://search.nixos.org/packages?channel=unstable&type=packages&query={}"
          # Extra qutebrowser configuration.
        ''
      }
  '';
}
