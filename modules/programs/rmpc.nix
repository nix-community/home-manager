{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    mkEnableOption
    mkPackageOption
    mkOption
    types
    ;

  cfg = config.programs.rmpc;
in
{
  meta.maintainers = with lib.maintainers; [
    qacow37
  ];

  options.programs.rmpc = {
    enable = mkEnableOption "rmpc";
    package = mkPackageOption pkgs "rmpc" { nullable = true; };
    config = mkOption {
      type = types.lines;
      default = "";
      example = ''
        (
            address: "127.0.0.1:6600",
            password: None,
            theme: None,
            cache_dir: None,
            on_song_change: None,
            volume_step: 5,
            max_fps: 30,
            scrolloff: 0,
            wrap_navigation: false,
            enable_mouse: true,
            enable_config_hot_reload: true,
            status_update_interval_ms: 1000,
            select_current_song_on_change: false,
            browser_song_sort: [Disc, Track, Artist, Title],
        )
      '';
      description = ''
        Configuration settings for rmpc in the Rusty Object Notation
        format. All available options can be found in the official
        documentation at <https://rmpc.mierak.dev/configuration/>.
      '';
    };
    themes = lib.mkOption {
      type = types.attrsOf types.lines;
      default = { };
      example = ''
        (
            default_album_art_path: None,
            format_tag_separator: " | ",
            browser_column_widths: [20, 38, 42],
            background_color: None,
            symbols: (
                song: "S",
                dir: "D",
                playlist: "P",
                marker: "M",
                ellipsis: "...",
                song_style: None,
                dir_style: None,
                playlist_style: None,
            ),
        )
      '';
      description = ''
        Theme configuration settings for rmpc in the Rusty Object Notation
        format. Every attribute gets its own theme file. All available
        options can be found in the official
        documentation at <https://rmpc.mierak.dev/configuration/theme>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile = mkMerge [
      (lib.mapAttrs' (
        name: content: lib.nameValuePair "rmpc/themes/${name}.ron" { text = content; }
      ) cfg.themes)
      (mkIf (cfg.config != "") {
        "rmpc/config.ron".text = cfg.config;
      })
    ];
  };
}
