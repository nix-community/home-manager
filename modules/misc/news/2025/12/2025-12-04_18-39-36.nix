{ config, lib, ... }:

{
  time = "2025-12-04T18:39:36+00:00";
  condition = lib.versionAtLeast config.home.stateVersion "26.05";
  message = ''
    The 'home.uid' option is now required for state version 26.05 and later.

    When using Home Manager as a NixOS or nix-darwin module, this value is
    automatically set from 'users.users.<name>.uid' when that option is defined.

    For standalone usage, or when the system user has no explicit UID, add to
    your configuration:

        home.uid = 1000;  # Replace with your actual UID (run 'id -u')
  '';
}
