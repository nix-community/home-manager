{ pkgs, ... }:
{
  time = "2026-03-04T09:47:58+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'services.secret-service'.

    The D-Bus secret service API allows applications to store and access
    secrets securely in a service running in the user's login session. It
    is implemented by various backends such as gnome-keyring, kwallet, and
    keepassxc. This module adds functionality to declaratively manage
    secrets in the secret service. The defined secrets get inserted into
    the secret service after the session started and the default collection
    is unlocked, and are removed again when the session ends.
  '';
}
