{ lib, pkgs, ... }:
{
  telegram-bindings = ./bindings.nix;
  telegram-disabled = ./disabled.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  telegram-systemd = ./systemd.nix;
}
