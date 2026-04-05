{ pkgs, ... }:

{
  time = "2026-03-14T14:53:25+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'services.sunsetr'.
  '';
}
