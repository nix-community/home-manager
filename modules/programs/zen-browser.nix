{ lib, ... }:
let
  modulePath = [ "programs" "zen-browser" ];
  mkFirefoxModule = import ./firefox/mkFirefoxModule.nix;
in {
  meta.maintainers = [ lib.hm.maintainers.HeitorAugustoLN ];

  imports = [
    (mkFirefoxModule {
      inherit modulePath;
      name = "Zen Browser";
      wrappedPackageName = "zen-browser";
      unwrappedPackageName = "zen-browser-unwrapped";
      visible = true;

      platforms = {
        linux = {
          vendorPath = ".zen";
          configPath = ".zen";
        };
        darwin = { configPath = "Library/Application Support/Zen"; };
      };
    })
  ];
}
