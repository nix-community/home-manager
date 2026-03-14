modulePath:
{ config, lib, ... }:

let
  firefoxMockOverlay = import ./setup-firefox-mock-overlay.nix modulePath;

  extensionWithoutAddonId = config.lib.test.mkStubPackage {
    name = "extension-without-addon-id";
  };
in
{
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig (
    lib.setAttrByPath modulePath {
      enable = true;
      globalExtensions = [ extensionWithoutAddonId ];
    }
    // {
      test.asserts.assertions.expected = [
        "${lib.showOption modulePath}.globalExtensions requires each package to expose addonId in passthru."
      ];
    }
  );
}
