{ lib, pkgs, ... }:

{
  lazysql-example-config = ./example-config.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  lazysql-darwin-default-config = ./darwin-default-config.nix;
  lazysql-darwin-disabled-config = ./darwin-disabled-config.nix;
}
