modulePath:
{ config, lib, ... }:

with lib;

let

  cfg = getAttrFromPath modulePath config;

  firefoxMockOverlay = import ./setup-firefox-mock-overlay.nix modulePath;

in {
  imports = [ firefoxMockOverlay ];

  config = mkIf config.test.enableBig ({
    test.asserts.assertions.expected = [''
      Must not have a ${cfg.name} profile with an existing ID but
        - ID 1 is used by first, second''];
  } // setAttrByPath modulePath {
    enable = true;

    profiles = {
      first = {
        isDefault = true;
        id = 1;
      };
      second = { id = 1; };
    };
  });
}
