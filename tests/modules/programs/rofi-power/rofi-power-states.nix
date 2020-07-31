{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.rofi.power = {
      enable = true;
      states.hibernate = false;
    };

    nixpkgs.overlays = [
      (self: super: { rofi-power = pkgs.writeScriptBin "dummy-rofi-power" ""; })
    ];

    nmt.script = ''
      assertFileContent \
        home-files/.config/rofi-power/states \
        ${
          pkgs.writeText "rofi-power-expected-states" ''
            [Cancel]
            Logout
            Shutdown
            Reboot
            Suspend
            Hybrid-sleep
            Suspend-then-hibernate''
        }
    '';
  };
}
