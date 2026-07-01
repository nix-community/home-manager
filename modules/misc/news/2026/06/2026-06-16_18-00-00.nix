{ config, ... }:
{
  time = "2026-06-16T18:00:00+00:00";
  condition = config.programs.attic-client.enable;
  message = ''
    A new module is available: `programs.attic-client`.

    It manages the client configuration for the Attic Nix binary cache.
  '';
}
