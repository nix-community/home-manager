{ pkgs, ... }:
{
  time = "2025-11-27T07:22:14+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    A new module is available: 'programs.infat'.
    Infat is a command line tool to set default openers
    for file formats and url schemes on macOS.
  '';
}
