{
  pkgs,
  ...
}:
{
  time = "2026-04-15T11:57:57+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    A new module is available: `programs.macos-terminal`.

    This module allows for configuration of preferences for the macOS
    Terminal.app application.
  '';
}
