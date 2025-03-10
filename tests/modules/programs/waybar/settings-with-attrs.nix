{ config, lib, pkgs, ... }:

{
  config = {
    home.stateVersion = "21.11";

    programs.waybar = {
      package = config.lib.test.mkStubPackage { outPath = "@waybar@"; };
      enable = true;
      settings = let
        settingsComplex = (import ./settings-complex.nix {
          inherit config lib pkgs;
        }).config.programs.waybar.settings;
      in {
        mainBar = builtins.head settingsComplex;
        secondaryBar = builtins.elemAt settingsComplex 1;
      };
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/waybar/style.css
      assertFileContent \
        home-files/.config/waybar/config \
        ${./settings-complex-expected.json}
    '';
  };
}
