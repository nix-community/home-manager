{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption mkPackageOption mkOption types literalExpression mkIf;

  cfg = config.programs.spotify-player;
  tomlFormat = pkgs.formats.toml { };

in {
  meta.maintainers = with lib.hm.maintainers; [ diniamo ];

  options.programs.spotify-player = {
    enable = mkEnableOption "spotify-player";

    package = mkPackageOption pkgs "spotify-player" { };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          theme = "default";
          playback_window_position = "Top";
          copy_command = {
            command = "wl-copy";
            args = [];
          };
          device = {
            audio_cache = false;
            normalization = false;
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/spotify-player/app.toml`.

        See
        <https://github.com/aome510/spotify-player/blob/master/docs/config.md#general>
        for the full list of options.
      '';
    };

    themes = mkOption {
      type = types.listOf tomlFormat.type;
      default = [ ];
      example = literalExpression ''
        [
          {
            name = "default2";
            palette = {
              black = "black";
              red = "red";
              green = "green";
              yellow = "yellow";
              blue = "blue";
              magenta = "magenta";
              cyan = "cyan";
              white = "white";
              bright_black = "bright_black";
              bright_red = "bright_red";
              bright_green = "bright_green";
              bright_yellow = "bright_yellow";
              bright_blue = "bright_blue";
              bright_magenta = "bright_magenta";
              bright_cyan = "bright_cyan";
              bright_white = "bright_white";
            };
            component_style = {
              block_title = { fg = "Magenta"; };
              border = {};
              playback_track = { fg = "Cyan"; modifiers = ["Bold"]; };
              playback_artists = { fg = "Cyan"; modifiers = ["Bold"]; };
              playback_album = { fg = "Yellow"; };
              playback_metadata = { fg = "BrightBlack"; };
              playback_progress_bar = { bg = "BrightBlack"; fg = "Green"; };
              current_playing = { fg = "Green"; modifiers = ["Bold"]; };
              page_desc = { fg = "Cyan"; modifiers = ["Bold"]; };
              table_header = { fg = "Blue"; };
              selection = { modifiers = ["Bold" "Reversed"]; };
            };
          }
        ]
      '';
      description = ''
        Configuration written to the `themes` field of
        {file}`$XDG_CONFIG_HOME/spotify-player/theme.toml`.

        See
        <https://github.com/aome510/spotify-player/blob/master/docs/config.md#themes>
        for the full list of options.
      '';
    };

    keymaps = mkOption {
      type = types.listOf tomlFormat.type;
      default = [ ];
      example = literalExpression ''
        [
          {
            command = "NextTrack";
            key_sequence = "g n";
          }
          {
            command = "PreviousTrack";
            key_sequence = "g p";
          }
          {
            command = "Search";
            key_sequence = "C-c C-x /";
          }
          {
            command = "ResumePause";
            key_sequence = "M-enter";
          }
          {
            command = "None";
            key_sequence = "q";
          }
        ]
      '';
      description = ''
        Configuration written to the `keymaps` field of
        {file}`$XDG_CONFIG_HOME/spotify-player/keymap.toml`.

        See
        <https://github.com/aome510/spotify-player/blob/master/docs/config.md#keymaps>
        for the full list of options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "spotify-player/app.toml" = mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "spotify-player-app" cfg.settings;
      };

      "spotify-player/theme.toml" = mkIf (cfg.themes != [ ]) {
        source =
          tomlFormat.generate "spotify-player-theme" { inherit (cfg) themes; };
      };

      "spotify-player/keymap.toml" = mkIf (cfg.keymaps != [ ]) {
        source = tomlFormat.generate "spotify-player-keymap" {
          inherit (cfg) keymaps;
        };
      };
    };
  };
}
