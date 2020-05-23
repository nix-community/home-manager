{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.qutebrowser = {
      enable = true;

      keyBindings = {
        normal = {
          "<Ctrl-v>" = "spawn mpv {url}";
          ",l" = ''config-cycle spellcheck.languages ["en-GB"] ["en-US"]'';
        };
        prompt = { "<Ctrl-y>" = "prompt-yes"; };
      };
    };

    nixpkgs.overlays = [
      (self: super: {
        qutebrowser = pkgs.writeScriptBin "dummy-qutebrowser" "";
      })
    ];

    nmt.script = ''
      assertFileContent \
        $home_files/.config/qutebrowser/config.py \
        ${
          pkgs.writeText "qutebrowser-expected-config.py" ''
            config.bind(",l", "config-cycle spellcheck.languages [\"en-GB\"] [\"en-US\"]", mode="normal")
            config.bind("<Ctrl-v>", "spawn mpv {url}", mode="normal")
            config.bind("<Ctrl-y>", "prompt-yes", mode="prompt")''
        }
    '';
  };
}
