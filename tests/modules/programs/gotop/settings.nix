{ config, lib, pkgs, ... }:

with lib;

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  configPath = if isDarwin then
    "home-files/Library/Application\\ Support/gotop/gotop.conf"
  else
    "home-files/.config/gotop/gotop.conf";
in {
  config = {
    programs.gotop = {
      enable = true;

      settings = {
        colorscheme = "solarized";
        layout = "kitchensink";
      };
    };

    nixpkgs.overlays =
      [ (self: super: { gotop = pkgs.writeScriptBin "dummy-gotop" ""; }) ];

    nmt.script = ''
      assertFileContent \
        ${configPath} \
          ${
            pkgs.writeText "gotop-expected-config.conf" ''
              colorscheme=solarized
              layout=kitchensink
            ''
          }
    '';
  };
}
