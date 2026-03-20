{ config, pkgs, ... }:

{
  time = "2026-01-27T21:41:51+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin && config.launchd.enable;
  message = ''

    The `launchd` module now ensures that the Nix store is mounted and
    available before starting any agents. This improves reliability on macOS
    where `launchd` might otherwise attempt to start agents before the Nix
    store is ready.
  '';
}
