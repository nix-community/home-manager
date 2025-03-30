{ lib, ... }:
let
  modulePath = [ "programs" "floorp" ];

  mkFirefoxModule = import ./firefox/mkFirefoxModule.nix;
in {
  meta.maintainers = [ lib.hm.maintainers.bricked ];

  imports = [
    (mkFirefoxModule {
      inherit modulePath;
      name = "Floorp";
      wrappedPackageName = "floorp";
      unwrappedPackageName = "floorp-unwrapped";
      visible = true;

      platforms.linux = { configPath = ".floorp"; };
      platforms.darwin = { configPath = "Library/Application Support/Floorp"; };
    })
  ];
}
