{ pkgs, ... }:

{
  time = "2025-09-20T12:29:51+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `programs.animdl`

    A highly efficient, fast, powerful and light-weight
    anime downloader and streamer for your favorite anime.
  '';
}
