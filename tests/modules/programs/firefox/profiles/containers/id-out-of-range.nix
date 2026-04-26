modulePath:
{ config, lib, ... }:

let

  firefoxMockOverlay = import ../../setup-firefox-mock-overlay.nix modulePath;

in
{
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig (
    {
      test.asserts.assertions.expected = [ "Container id must be between 1 and 4294967293" ];
    }
    // lib.setAttrByPath modulePath {
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
    }
  );
}
