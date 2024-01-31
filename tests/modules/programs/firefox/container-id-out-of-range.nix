{ config, lib, ... }:

{
  imports = [ ./setup-firefox-mock-overlay.nix ];

  config = lib.mkIf config.test.enableBig {
    test.asserts.assertions.expected =
      [ "Container id must be smaller than 4294967294 (2^32 - 2)" ];

    programs.firefox = {
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
    };
  };
}
