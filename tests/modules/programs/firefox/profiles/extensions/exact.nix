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

  bitwardenStubPkg = config.lib.test.mkStubPackage {
    name = "bitwarden";
    extraAttrs = {
      addonId = "{446900e4-71c2-419f-a6a7-df9c091e268b}";
      meta.mozPermissions = [
        "webNavigation"
        "webRequest"
        "webRequestBlocking"
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
            bitwardenStubPkg
          ];
          exactPermissions = true;
          settings = {
            ${uBlockStubPkg.addonId} = {
              permissions = [
                "privacy"
                "storage"
              ];
            };
            ${sponsorBlockStubPkg.addonId} = {
              permissions = [
                "storage"
                "scripting"
                "https://sponsor.ajay.app/*"
                "<all_urls>"
              ];
            };
            ${noscriptStubPkg.addonId} = {
              permissions = [
                "storage"
                "tabs"
                "https://github.com/*"
              ];
            };
            ${bitwardenStubPkg.addonId} = {
              permissions = [
                "webNavigation"
                "webRequest"
                "webRequestBlocking"
              ];
            };
          };
        };
      };
    }
    // {
      test.asserts.assertions.expected = [
        ''
          Extension ${uBlockStubPkg.addonId} requests permissions that weren't
          authorized: ["tabs"].
          Consider adding the missing permissions to
          '${lib.showOption modulePath}.profiles.extensions.extensions."${uBlockStubPkg.addonId}".permissions'.
        ''
        ''
          The following permissions were authorized, but extension
          ${sponsorBlockStubPkg.addonId} did not request them: ["<all_urls>"].
          Consider removing the redundant permissions from
          '${lib.showOption modulePath}.profiles.extensions.extensions."${sponsorBlockStubPkg.addonId}".permissions'.
        ''
        ''
          Extension ${noscriptStubPkg.addonId} requests permissions that weren't
          authorized: ["contextMenus"].
          Additionally, the following permissions were authorized,
          but extension ${noscriptStubPkg.addonId} did not request them:
          ["https://github.com/*"].
          Consider adjusting the permissions in
          '${lib.showOption modulePath}.profiles.extensions.extensions."${noscriptStubPkg.addonId}".permissions'.
        ''
      ];
    }
  );
}
