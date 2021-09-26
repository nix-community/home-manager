{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.waybar = {
      package = config.lib.test.mkStubPackage { outPath = "@waybar@"; };
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
