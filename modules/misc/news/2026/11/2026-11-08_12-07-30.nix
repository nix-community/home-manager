{ pkgs, ... }:
{
  time = "2026-11-08T12:07:30+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    A new module is available: 'programs.karabiner-elements'.

    Karabiner-Elements is a powerful and stable keyboard customizer for macOS.
  '';
}
