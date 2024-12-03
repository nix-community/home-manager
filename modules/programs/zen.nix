{ lib, ... }:

with lib;

let

  modulePath = [ "programs" "zen" ];

  moduleName = concatStringsSep "." modulePath;

  mkFirefoxModule = import ./firefox/mkFirefoxModule.nix;

in {
  meta.maintainers = [ maintainers._0x006e ];

  imports = [
    (mkFirefoxModule {
      inherit modulePath;
      name = "Zen";
      wrappedPackageName = "zen-browser";
      unwrappedPackageName = "zen-browser-unwrapped";
      visible = true;

      platforms.linux = rec {
        vendorPath = ".zen";
        configPath = ".zen";
      };
      platforms.darwin = {
        vendorPath = "Library/Application Support/Zen";
        configPath = "Library/Application Support/Zen";
      };
    })

    (mkRemovedOptionModule (modulePath ++ [ "extensions" ]) ''

      Extensions are now managed per-profile. That is, change from

        ${moduleName}.extensions = [ foo bar ];

      to

        ${moduleName}.profiles.myprofile.extensions = [ foo bar ];'')
    (mkRemovedOptionModule (modulePath ++ [ "enableAdobeFlash" ])
      "Support for this option has been removed.")
    (mkRemovedOptionModule (modulePath ++ [ "enableGoogleTalk" ])
      "Support for this option has been removed.")
    (mkRemovedOptionModule (modulePath ++ [ "enableIcedTea" ])
      "Support for this option has been removed.")
  ];
}
