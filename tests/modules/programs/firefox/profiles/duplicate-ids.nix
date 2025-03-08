modulePath:
{ config, lib, ... }:

let

  cfg = lib.getAttrFromPath modulePath config;

  firefoxMockOverlay = import ../setup-firefox-mock-overlay.nix modulePath;

in {
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig ({
    test.asserts.assertions.expected = [''
      Must not have a ${cfg.name} profile with an existing ID but
        - ID 1 is used by first, second''];
  } // lib.setAttrByPath modulePath {
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
