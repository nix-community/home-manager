{ pkgs, ... }:

{
  time = "2025-05-02T03:14:36+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'services.clipcat'.

    Clipcat is a clipboard manager for Wayland and X11 with a daemon/client
    architecture. It offers a secure way to store and manage clipboard history
    with features like content filtering, custom maximum item count, and
    history persistence. The module provides options to configure the daemon,
    enable clipboard syncing, and set up the included GTK client.
  '';
}
