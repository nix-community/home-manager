{ pkgs, ... }:

{
  time = "2024-09-13T08:58:17+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.trayscale'.

    An unofficial GUI wrapper around the Tailscale CLI client.
  '';
}
