{ config, lib, pkgs, ... }:

with lib;

{
  config = {
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
            c.tabs.tabs_are_windows = True
            # Extra qutebrowser configuration.
          ''
        }
    '';
  };
}
