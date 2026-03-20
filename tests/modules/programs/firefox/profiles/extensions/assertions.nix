modulePath:
{ config, lib, ... }:

let

  firefoxMockOverlay = import ../../setup-firefox-mock-overlay.nix modulePath;

  uBlockStubPkg = config.lib.test.mkStubPackage {
    name = "ublock-origin-dummy";
    extraAttrs = {
      addonId = "uBlock0@raymondhill.net";
      meta.mozPermissions = [
        "privacy"
        "storage"
        "tabs"
        "<all_urls>"
        "http://*/*"
        "https://github.com/*"
      ];
    };
  };
in
{
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig (
    lib.setAttrByPath modulePath {
      enable = true;
      profiles.extensions = {
        extensions = {
          packages = [ uBlockStubPkg ];
          settings = {
            "uBlock0@raymondhill.net" = {
              settings = {
                selectedFilterLists = [
                  "ublock-filters"
                  "ublock-badware"
                  "ublock-privacy"
                  "ublock-unbreak"
                  "ublock-quick-fixes"
                ];
              };
              permissions = [
                "alarms"
                "tabs"
                "https://github.com/*"
              ];
            };
            "unknown@example.com".permissions = [ ];
          };
        };
      };
    }
    // {
      test.asserts.assertions.expected = [
        ''
          Using '${lib.showOption modulePath}.profiles.extensions.extensions.settings' will override all
          previous extensions settings. Enable
          '${lib.showOption modulePath}.profiles.extensions.extensions.force' to acknowledge this.
        ''
        ''
          Extension uBlock0@raymondhill.net requests permissions that weren't
          authorized: ["privacy","storage","<all_urls>","http://*/*"].
          Consider adding the missing permissions to
          '${lib.showOption modulePath}.profiles.extensions.extensions."uBlock0@raymondhill.net".permissions'.
        ''
        ''
          Must have exactly one extension with addonId 'unknown@example.com'
          in '${lib.showOption modulePath}.profiles.extensions.extensions.packages' but found 0.
        ''
      ];
    }
  );
}
