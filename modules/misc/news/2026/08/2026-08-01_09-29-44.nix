{ pkgs, ... }:
{
  time = "2026-08-01T09:29:44+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available `programs.noctalia`.

    Noctalia is a sleek, customizable shell crafted for Wayland.
  '';
}
