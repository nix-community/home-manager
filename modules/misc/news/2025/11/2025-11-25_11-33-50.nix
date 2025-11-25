{ config, ... }:

{
  time = "2025-11-25T11:33:50+00:00";
  condition = config.programs.nix-index.enable && config.programs.nushell.enable;
  message = ''
    The nix-index module now adds a command-not-found handler to Nushell by default.

    This can be disabled:
      programs.nix-index.enableNushellIntegration = false;
  '';
}
