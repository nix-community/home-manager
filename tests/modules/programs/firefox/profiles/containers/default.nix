modulePath:
{ config, lib, ... }:
let

  cfg = lib.getAttrFromPath modulePath config;

  firefoxMockOverlay = import ../../setup-firefox-mock-overlay.nix modulePath;

in
{
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig (
    lib.setAttrByPath modulePath {
      enable = true;
      profiles.containers = {
        containers = {
          "shopping" = {
            icon = "circle";
            color = "yellow";
          };
        };
      };
    }
    // {
      nmt.script = ''
        assertFileContent \
          "home-files/${cfg.profilesPath}/containers/containers.json" \
          ${./expected-containers.json}
      '';
    }
  );
}
