modulePath:
{ config, lib, pkgs, ... }:
let firefoxMockOverlay = import ../../setup-firefox-mock-overlay.nix modulePath;
in {
  imports = [ firefoxMockOverlay ];

  config = lib.mkIf config.test.enableBig (lib.setAttrByPath modulePath {
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
    nmt.script = let
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
      profilePath = if isDarwin then
        "Library/Application Support/Firefox/Profiles"
      else
        ".mozilla/firefox";
    in ''
      assertFileContent \
        "home-files/${profilePath}/containers/containers.json" \
        ${./expected-containers.json}
    '';
  });
}
