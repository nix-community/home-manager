{ pkgs, ... }:

{
  time = "2024-02-21T23:01:27+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'wayland.windowManager.river'.
  '';
}
