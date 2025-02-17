{ lib, ... }:

with lib;

let

  modulePath = [ "programs" "floorp" ];

  mkFirefoxModule = import ./firefox/mkFirefoxModule.nix;

in {
  meta.maintainers = [ hm.maintainers.bricked ];

  imports = [
    (mkFirefoxModule {
      inherit modulePath;
      name = "Floorp";
      wrappedPackageName = "floorp";
      unwrappedPackageName = "floorp-unwrapped";
      visible = true;

      platforms.linux = {
        configPath = ".floorp";
        vendorPath = ".mozilla";
      };
      platforms.darwin = {
        configPath = "Library/Application Support/Floorp";
        vendorPath = "Library/Application Support/Mozilla";
      };
    })
  ];
}
