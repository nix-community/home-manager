{ pkgs, ... }:

{
  time = "2025-05-08T15:45:24+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.wayprompt'.

    Wayprompt is a password prompter for Wayland, including a drop-in
    replacement for GnuPG’s pinentry ('pinentry-wayprompt').

    Note that the Wayland compositor must support the Layer Shell protocol.
  '';
}
