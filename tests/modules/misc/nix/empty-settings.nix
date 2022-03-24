{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    nix = { package = config.lib.test.mkStubPackage { }; };

    nmt.script = ''
      assertPathNotExists home-files/.config/nix
    '';
  };
}
