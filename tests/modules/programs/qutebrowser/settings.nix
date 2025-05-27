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
      spellcheck.languages = [
        "en-US"
        "sv-SE"
      ];
      tabs.tabs_are_windows = true;
    };

    extraConfig = ''
      # Extra qutebrowser configuration.
    '';
  };

  nmt.script =
    let
      qutebrowserConfig =
        if pkgs.stdenv.hostPlatform.isDarwin then
          ".qutebrowser/config.py"
        else
          ".config/qutebrowser/config.py";
    in
    ''
      assertFileContent \
        home-files/${qutebrowserConfig} \
        ${builtins.toFile "qutebrowser-expected-config.py" ''
          config.load_autoconfig(False)
          config.set("colors.hints.bg", "#000000")
          config.set("colors.hints.fg", "#ffffff")
          config.set("colors.tabs.bar.bg", "#000000")
          config.set("spellcheck.languages", ["en-US", "sv-SE"])
          config.set("tabs.tabs_are_windows", True)
          # Extra qutebrowser configuration.
        ''}
    '';
}
