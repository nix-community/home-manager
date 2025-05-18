{ pkgs, ... }:

{
  time = "2024-04-28T20:27:08+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.psd'.

    Profile-sync-daemon (psd) is a tiny pseudo-daemon designed to manage
    your browser's profile in tmpfs and to periodically sync it back to
    your physical disc (HDD/SSD).
  '';
}
