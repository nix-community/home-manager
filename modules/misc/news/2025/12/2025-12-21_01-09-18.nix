{ pkgs, ... }:
{
  time = "2025-12-21T09:09:18+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'sunpaper'
  '';
}
