modulePath:
{ config, lib, pkgs, ... }:

with lib;

let

  cfg = getAttrFromPath modulePath config;

  firefoxMockOverlay = import ../../setup-firefox-mock-overlay.nix modulePath;

in {
  imports = [ firefoxMockOverlay ];

  config = mkIf config.test.enableBig (setAttrByPath modulePath {
    enable = true;
    profiles.containers = {
      containers = {
        "shopping" = {
          icon = "circle";
          color = "yellow";
        };
      };
    };
  } // {
    nmt.script = ''
      assertFileContent \
        home-files/${cfg.configPath}/containers/containers.json \
        ${./expected-containers.json}
    '';
  });
}
