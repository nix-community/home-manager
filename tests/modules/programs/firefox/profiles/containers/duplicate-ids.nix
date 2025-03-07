modulePath:
{ config, lib, ... }:

let

  cfg = lib.getAttrFromPath modulePath config;

  firefoxMockOverlay = import ../../setup-firefox-mock-overlay.nix modulePath;

in {
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig ({
    test.asserts.assertions.expected = [''
      Must not have a ${cfg.name} container with an existing ID but
        - ID 9 is used by dangerous, shopping''];
  } // lib.setAttrByPath modulePath {
    enable = true;

    profiles = {
      my-profile = {
        isDefault = true;
        id = 1;

        containers = {
          "shopping" = {
            id = 9;
            color = "blue";
            icon = "circle";
          };
          "dangerous" = {
            id = 9;
            color = "red";
            icon = "circle";
          };
        };
      };
    };
  });
}
