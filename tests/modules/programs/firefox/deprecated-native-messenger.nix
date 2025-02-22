modulePath:
{ config, lib, ... }:
let
  moduleName = lib.concatStringsSep "." modulePath;

  firefoxMockOverlay = import ./setup-firefox-mock-overlay.nix modulePath;
in {
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig (lib.setAttrByPath modulePath {
    enable = true;
    enableGnomeExtensions = true;
  } // {
    test.asserts.warnings.expected = [''
      Using '${moduleName}.enableGnomeExtensions' has been deprecated and
      will be removed in the future. Please change to overriding the package
      configuration using '${moduleName}.package' instead. You can refer to
      its example for how to do this.
    ''];
  });
}
