modulePath:
{ config, lib, ... }:

let

  firefoxMockOverlay = import ../../setup-firefox-mock-overlay.nix modulePath;

  uBlockStubPkg = config.lib.test.mkStubPackage {
    name = "ublock-origin-dummy";
    extraAttrs = {
      addonId = "uBlock0@raymondhill.net";
      meta.mozPermissions = [
        "<all_urls>"
        "http://*/*"
        "https://github.com/*"
      ];
    };
  };

  sponsorBlockStubPkg = config.lib.test.mkStubPackage {
    name = "sponsorblock";
    extraAttrs = {
      addonId = "sponsorBlocker@ajay.app";
      meta.mozPermissions = [
        "storage"
        "scripting"
        "https://sponsor.ajay.app/*"
      ];
    };
  };

  noscriptStubPkg = config.lib.test.mkStubPackage {
    name = "noscript";
    extraAttrs = {
      addonId = "{73a6fe31-595d-460b-a920-fcc0f8843232}";
      meta.mozPermissions = [
        "contextMenus"
        "storage"
        "tabs"
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
          packages = [
            uBlockStubPkg
            sponsorBlockStubPkg
            noscriptStubPkg
          ];
          exhaustivePermissions = true;
          settings = {
            ${uBlockStubPkg.addonId} = {
              permissions = [
                "<all_urls>"
                "http://*/*"
                "https://github.com/*"
              ];
            };
            ${noscriptStubPkg.addonId} = {
              permissions = [
                "contextMenus"
              ];
            };
          };
        };
      };
    }
    // {
      test.asserts.assertions.expected = [
        ''
          Extension ${sponsorBlockStubPkg.addonId} requests permissions that weren't
          authorized: ["storage","scripting","https://sponsor.ajay.app/*"].
          Consider adding the missing permissions to
          '${lib.showOption modulePath}.profiles.extensions.extensions."${sponsorBlockStubPkg.addonId}".permissions'.
        ''
        ''
          Extension ${noscriptStubPkg.addonId} requests permissions that weren't
          authorized: ["storage","tabs"].
          Consider adding the missing permissions to
          '${lib.showOption modulePath}.profiles.extensions.extensions."${noscriptStubPkg.addonId}".permissions'.
        ''
      ];
    }
  );
}
