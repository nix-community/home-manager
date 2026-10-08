modulePath:
{ config, lib, ... }:

let
  firefoxMockOverlay = import ../../setup-firefox-mock-overlay.nix modulePath;
in
{
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig (
    lib.setAttrByPath modulePath {
      enable = true;
      profiles.extensions = {
        extensions.settings = {
          "forced@example.com" = {
            force = true;
            settings.enabled = true;
          };
          "unforced@example.com".settings.enabled = true;
        };
      };
    }
    // {
      test.asserts.assertions.expected = [
        ''
          Using '${lib.showOption modulePath}.profiles.extensions.extensions.settings' will override all
          previous extensions settings. Enable either
          '${lib.showOption modulePath}.profiles.extensions.extensions.force' or the corresponding
          '${lib.showOption modulePath}.profiles.extensions.extensions.settings.<extensionId>.force'
          to acknowledge this.
        ''
      ];
    }
  );
}
