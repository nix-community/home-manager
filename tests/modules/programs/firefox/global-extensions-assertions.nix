modulePath:
{
  config,
  lib,
  pkgs,
  ...
}:

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
      package = lib.mkIf pkgs.stdenv.hostPlatform.isLinux null;
      globalExtensions = [ extensionWithoutAddonId ];
    }
    // {
      test.asserts.assertions.expected =
        lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          "'${lib.showOption modulePath}.globalExtensions' requires '${lib.showOption modulePath}.package' to be set to a non-null value unless '${lib.showOption modulePath}.darwinDefaultsId' is set on Darwin."
        ]
        ++ [
          "${lib.showOption modulePath}.globalExtensions requires each package to expose addonId in passthru."
        ];
    }
  );
}
