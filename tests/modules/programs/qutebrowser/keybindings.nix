{ lib, pkgs, ... }:

{
  programs.qutebrowser = {
    enable = true;

    enableDefaultBindings = false;

    keyBindings = {
      normal = {
        ":" = null;
        "<Ctrl-v>" = "spawn mpv {url}";
        ",l" = ''config-cycle spellcheck.languages ["en-GB"] ["en-US"]'';
        "<F1>" = lib.mkMerge [
          "config-cycle tabs.show never always"
          "config-cycle statusbar.show in-mode always"
          "config-cycle scrolling.bar never always"
        ];
      };
      prompt = { "<Ctrl-y>" = "prompt-yes"; };
    };
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
          c.bindings.default = {}
          config.bind(",l", "config-cycle spellcheck.languages [\"en-GB\"] [\"en-US\"]", mode="normal")
          config.unbind(":", mode="normal")
          config.bind("<Ctrl-v>", "spawn mpv {url}", mode="normal")
          config.bind("<F1>", "config-cycle tabs.show never always ;; config-cycle statusbar.show in-mode always ;; config-cycle scrolling.bar never always", mode="normal")
          config.bind("<Ctrl-y>", "prompt-yes", mode="prompt")''
      }
  '';
}
