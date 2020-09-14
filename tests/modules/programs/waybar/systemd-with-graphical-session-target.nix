{ config, lib, pkgs, ... }:

with lib;

let
  package = pkgs.writeScriptBin "dummy-waybar" "" // { outPath = "@waybar@"; };
in {
  config = {
    programs.waybar = {
      inherit package;
      enable = true;
      systemd.enable = true;
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/waybar/config
      assertPathNotExists home-files/.config/waybar/style.css

      assertFileContent \
        home-files/.config/systemd/user/waybar.service \
        ${./systemd-with-graphical-session-target.service}
    '';
  };
}
