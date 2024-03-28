{ lib, ... }:

with lib;

let

  modulePath = [ "programs" "firefox" ];

  moduleName = concatStringsSep "." modulePath;

  mkFirefoxModule = import ./firefox/mkFirefoxModule.nix;

in {
  meta.maintainers =
    [ maintainers.rycee maintainers.kira-bruneau maintainers.bricked ];

  imports = [
    (mkFirefoxModule modulePath {
      name = "Firefox";
      wrappedPackageName = "firefox";
      unwrappedPackageName = "firefox-unwrapped";
      visible = true;

      platforms.linux = rec {
        vendorPath = ".mozilla";
        configPath = "${vendorPath}/firefox";
      };
      platforms.darwin = {
        vendorPath = "Library/Application Support/Mozilla";
        configPath = "Library/Application Support/Firefox";
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
