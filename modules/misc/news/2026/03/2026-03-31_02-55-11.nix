{ pkgs, ... }:
{
  time = "2026-03-31T01:55:11+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `services.pipewire`.

    The module provides options for configuring the PipeWire server, the
    client library, the PulseAudio and JACK emulators, the WirePlumber session
    manager, and the LV2 plugins for use in filter chains.

    The module does *not* provide a way to install PipeWire, as that should be
    done through your NixOS config (or system package manager).
  '';
}
