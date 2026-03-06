{ pkgs, ... }:
{
  time = "2026-02-22T09:45:54+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `services.mpdris2-rs`

    Adds a module for mpdris2-rs, a lightweight implementation of the MPD to
    D-Bus bridge.
  '';
}
