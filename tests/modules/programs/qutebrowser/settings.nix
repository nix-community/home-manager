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

    nixpkgs.overlays = [
      (self: super: {
        qutebrowser = pkgs.writeScriptBin "dummy-qutebrowser" "";
      })
    ];

    nmt.script = ''
      assertFileContent \
        home-files/.config/qutebrowser/config.py \
        ${
          pkgs.writeText "qutebrowser-expected-config.py" ''
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
