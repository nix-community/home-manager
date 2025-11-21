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

  cfg = config.programs.anime-downloader;
  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.anime-downloader = {
    enable = mkEnableOption "anime-downloader";
    package = mkPackageOption pkgs "anime-downloader" { nullable = true; };
    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        dl = {
          aria2c_for_torrents = false;
          chunk_size = "10";
          download_dir = ".";
          external_downloader = "{aria2}";
          fallback_qualities = [
            "720p"
            "480p"
            "360p"
          ];
          file_format = "{anime_title}/{anime_title}_{ep_no}";
          force_download = false;
          player = null;
          provider = "twist.moe";
          quality = "1080p";
          skip_download = false;
          url = false;
        };
      };
      description = ''
        Configuration settings for anime-downloader. All available options can be found here:
        <https://anime-downlader.readthedocs.io/en/latest/usage/config.html#config-json>.
      '';
    };
  };

  config =
    let
      configDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/anime downloader"
        else
          "${lib.removePrefix config.home.homeDirectory config.xdg.configHome}/anime-downloader";
    in
    mkIf cfg.enable {
      assertions = [
        (lib.hm.assertions.assertPlatform "programs.anime-downloader" pkgs lib.platforms.linux)
      ];

      home.packages = mkIf (cfg.package != null) [ cfg.package ];
      home.file."${configDir}/config.json" = mkIf (cfg.settings != { }) {
        source = jsonFormat.generate "config.json" cfg.settings;
      };
    };
}
