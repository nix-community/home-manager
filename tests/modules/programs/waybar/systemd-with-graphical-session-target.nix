{ config, ... }:

{
  config = {
    home.stateVersion = "21.11";

    programs.waybar = {
      package = config.lib.test.mkStubPackage { outPath = "@waybar@"; };
      enable = true;
      systemd.enable = true;
      systemd.target = "sway-session.target";
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/waybar/config
      assertPathNotExists home-files/.config/waybar/style.css

      serviceFile=$(normalizeStorePaths home-files/.config/systemd/user/waybar.service)
      assertFileContent "$serviceFile" ${
        ./systemd-with-graphical-session-target.service
      }
    '';
  };
}
