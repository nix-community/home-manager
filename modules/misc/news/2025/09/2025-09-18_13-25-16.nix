{ pkgs, ... }:

{
  time = "2025-09-18T16:25:16+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `programs.abaddon`

    An alternative Discord client with voice support made with C++ and GTK 3
  '';
}
