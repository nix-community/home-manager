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
        webpage.darkmode.enabled = true;
      };
    };

    perDomainSettings = {
      "zoom.us" = {
        content = {
          autoplay = true;
          media.audio_capture = true;
          media.video_capture = true;
        };
      };
      "web.whatsapp.com".colors.webpage.darkmode.enabled = false;
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
          config.set("colors.webpage.darkmode.enabled", True)
          # Extra qutebrowser configuration.

          config.set("colors.webpage.darkmode.enabled", False, "web.whatsapp.com")
          config.set("content.autoplay", True, "zoom.us")
          config.set("content.media.audio_capture", True, "zoom.us")
          config.set("content.media.video_capture", True, "zoom.us")''}
    '';
}
