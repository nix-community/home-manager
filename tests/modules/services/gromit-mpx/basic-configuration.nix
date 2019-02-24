{ config, pkgs, ... }:

{
  services.gromit-mpx = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
    tools = [
      {
        device = "default";
        type = "pen";
        size = 5;
      }
      {
        device = "default";
        type = "eraser";
        size = 75;
        modifiers = [ "3" ];
      }
    ];
  };

  nmt.script = import ./nmt-script.nix ./basic-configuration.cfg;
}
