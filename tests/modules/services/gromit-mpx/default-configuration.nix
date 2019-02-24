{ config, pkgs, ... }:

{
  services.gromit-mpx = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
  };

  nmt.script = import ./nmt-script.nix ./default-configuration.cfg;
}
