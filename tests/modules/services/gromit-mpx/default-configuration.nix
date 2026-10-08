{ config, ... }:

{
  services.gromit-mpx = {
    enable = true;
    package = config.lib.test.mkStubPackage { };
  };

  nmt.script = (import ./nmt-script.nix ./default-configuration.cfg) + ''
    assertFileRegex home-files/.config/gromit-mpx.ini 'ShowIntroOnStartup=false'
  '';
}
