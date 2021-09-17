{ config, lib, pkgs, ... }:

with lib;

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  configPath = if isDarwin then
    "home-files/Library/Preferences/glow/glow.yml"
  else
    "home-files/.config/glow/glow.yml";
in {
  config = {
    programs.glow = {
      enable = true;

      settings = {
        style = "light";
        local = true;
        mouse = true;
        pager = true;
        width = 80;
      };
    };

    nixpkgs.overlays =
      [ (self: super: { glow = pkgs.writeScriptBin "dummy-glow" ""; }) ];

    nmt.script = ''
      assertFileContent \
        ${configPath} \
          ${
            pkgs.writeText "glow-expected-config.conf" ''
              {"local":true,"mouse":true,"pager":true,"style":"light","width":80}''
          }
    '';
  };
}
