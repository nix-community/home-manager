{ pkgs, ... }:

{
  time = "2025-04-26T03:16:59+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.onedrive'.

    OneDrive is Microsoft's cloud storage service. This module integrates
    the open source OneDrive client for Linux which provides synchronization
    capabilities between your local file system and OneDrive. The module allows
    configuring multiple OneDrive accounts, sync options, and notification
    preferences.
  '';
}
