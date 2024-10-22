modulePath:
{ config, lib, pkgs, ... }:

let

  cfg = lib.getAttrFromPath modulePath config;

  firefoxMockOverlay = import ./setup-firefox-mock-overlay.nix modulePath;

in {
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig
    (lib.setAttrByPath modulePath { enable = true; } // {
      home.stateVersion = "19.09";

      nmt.script = ''
        package=${cfg.package}
        finalPackage=${cfg.finalPackage}
        if [[ $package != $finalPackage ]]; then
          fail "Expected finalPackage ($finalPackage) to equal package ($package)"
        fi
      '';
    });
}
