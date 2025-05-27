{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.waveterm;

  formatter = pkgs.formats.json { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.waveterm = {
    enable = mkEnableOption "waveterm";
    package = mkPackageOption pkgs "waveterm" { nullable = true; };
    settings = mkOption {
      type = formatter.type;
      default = { };
      example = {
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
      description = ''
        Configuration settings for WaveTerm. All available options can be
        found here: <https://docs.waveterm.dev/config#configuration-keys>.
      '';
    };

    themes = mkOption {
      type = formatter.type;
      default = { };
      example = {
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
      description = ''
        User defined terminal themes. All the details about available options and
        format can be found here: <https://docs.waveterm.dev/config#terminal-theming>.
      '';
    };

    bookmarks = mkOption {
      type = formatter.type;
      default = { };
      example = {
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
      description = ''
        Bookmark definitions for WaveTerm. Details about the format and the options
        can be found here: <https://docs.waveterm.dev/config#webbookmarks-configuration>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."waveterm/settings.json" = mkIf (cfg.settings != { }) {
      source = formatter.generate "waveterm-settings" cfg.settings;
    };
    xdg.configFile."waveterm/termthemes.json" = mkIf (cfg.themes != { }) {
      source = formatter.generate "waveterm-themes" cfg.themes;
    };
    xdg.configFile."waveterm/bookmarks.json" = mkIf (cfg.settings != { }) {
      source = formatter.generate "waveterm-bookmarks" cfg.bookmarks;
    };
  };
}
