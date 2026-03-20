{ pkgs, ... }:
{
  time = "2025-05-12T22:21:57+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `programs.foliate`

    Foliate is a modern e-book reader tailored for GNOME.
  '';
}
