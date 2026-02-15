{ config, pkgs, ... }:

{
  time = "2025-12-17T22:05:17+00:00";
  condition = config.services.lorri.enabled || pkgs.stdenv.isDarwin;
  message = ''
    The option `services.lorri` is now supported on darwin.

    lorri is a nix-shell replacement for project development.
  '';
}
