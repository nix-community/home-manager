{ config, lib, pkgs, ... }:

with lib;

{
  programs.watson = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
  };

  nmt.script = let
    configDir = if pkgs.stdenv.hostPlatform.isDarwin then
      "home-files/Library/Application Support"
    else
      "home-files/.config";
  in ''
    assertPathNotExists ${configDir}/watson/config
  '';
}
