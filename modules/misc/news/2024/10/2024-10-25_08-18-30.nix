{ pkgs, ... }:

{
  time = "2024-10-25T08:18:30+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'nixGL'.

    NixGL solve the "OpenGL" problem with nix. The 'nixGL' module provides
    integration of NixGL into Home Manager. See the "GPU on non-NixOS
    systems" section in the Home Manager manual for more.
  '';
}
