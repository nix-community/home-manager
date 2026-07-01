{ pkgs, ... }:
{
  time = "2025-11-24T11:05:54+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'services.gotify-desktop'

    gotify-desktop is a small daemon to receive messages from a Gotify server
    and forward them as desktop notifications. It supports message priorities,
    automatic reconnection, retrieval of missed messages
    and automatic deletion of shown messages.
  '';
}
