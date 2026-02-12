{ lib, pkgs, ... }:

{
  flameshot-empty-settings = ./empty-settings.nix;
  flameshot-example-settings = ./example-settings.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  flameshot-service = ./service.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  flameshot-agent = ./launchd-agent.nix;
}
