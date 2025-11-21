{
  lib,
  pkgs,
  config,
  ...
}:

{
  programs.anime-downloader = {
    enable = true;
    settings = {
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
  };

  nmt.script =
    let
      configDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "Library/Application Support/anime downloader"
        else
          "${lib.removePrefix config.home.homeDirectory config.xdg.configHome}/anime-downloader";
    in
    ''
      assertFileExists "home-files/${configDir}/config.json"
      assertFileContent "home-files/${configDir}/config.json" \
        ${./config.json}
    '';
}
