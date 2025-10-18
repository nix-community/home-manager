{ pkgs, ... }:

{
  time = "2025-10-10T18:24:32+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `programs.anime-downloader`

    Anime-Downloader is a simple but powerful anime downloader and streamer.
  '';
}
