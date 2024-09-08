modulePath:
{ config, lib, ... }:

with lib;

let

  firefoxMockOverlay = import ./setup-firefox-mock-overlay.nix modulePath;

in {
  imports = [ firefoxMockOverlay ];

  config = mkIf config.test.enableBig ({
    test.asserts.assertions.expected =
      [ "Container id must be smaller than 4294967294 (2^32 - 2)" ];
  } // setAttrByPath modulePath {
    enable = true;

    profiles.my-profile = {
      isDefault = true;
      id = 1;

      containers = {
        "shopping" = {
          id = 4294967294;
          color = "blue";
          icon = "circle";
        };
      };
    };
  });
}
