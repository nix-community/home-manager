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
    types
    ;

  cfg = config.programs.rmpc;
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

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
        documentation at <https://mierak.github.io/rmpc/next/configuration/>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile = mkIf (cfg.config != "") {
      "rmpc/config.ron".text = cfg.config;
    };
  };
}
