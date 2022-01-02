{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.bottom = {
      enable = true;
      package = config.lib.test.mkStubPackage { };
    };

    nmt.script = let
      configDir = if pkgs.stdenv.isDarwin then
        "home-files/Library/Application Support"
      else
        "home-files/.config";
    in ''
      assertPathNotExists ${configDir}/bottom
    '';
  };
}
