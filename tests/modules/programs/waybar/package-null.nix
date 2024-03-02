{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    home.stateVersion = "23.11";

    programs.waybar = {
      package = null;
      enable = true;
    };

    test.stubs.waybar = {
      buildScript = "mkdir -p $out/bin; touch $out/bin/waybar";
      outPath = null;
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/waybar/style.css
      assertPathNotExists home-files/.config/waybar/config
      assertPathNotExists home-path/bin/waybar
    '';
  };
}
