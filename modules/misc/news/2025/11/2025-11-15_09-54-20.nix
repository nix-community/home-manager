{ pkgs, ... }:

{
  time = "2025-11-15T08:54:20+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.bluetuith'.

    bluetuith is a TUI-based Bluetooth connection manager, which can interact
    with Bluetooth adapters and devices. It aims to be a replacement to most
    Bluetooth managers, like blueman.
  '';
}
