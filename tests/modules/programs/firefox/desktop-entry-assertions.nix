modulePath:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  firefoxMockOverlay = import ./setup-firefox-mock-overlay.nix modulePath;
in
{
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig (
    lib.setAttrByPath modulePath {
      enable = true;
      package = null;
      profiles.default.desktopEntry.enable = true;
    }
    // {
      test.asserts.assertions.expected =
        lib.optionals (!pkgs.stdenv.hostPlatform.isLinux) [
          "'${lib.showOption modulePath}.profiles.<profile>.desktopEntry.enable' is only supported on Linux."
        ]
        ++ [
          "'${lib.showOption modulePath}.profiles.<profile>.desktopEntry.enable' requires '${lib.showOption modulePath}.package' to be set to a non-null value."
        ];
    }
  );
}
