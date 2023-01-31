{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    home.stateVersion = "22.11";

    programs.wlogout = {
      package = config.lib.test.mkStubPackage { outPath = "@wlogout@"; };
      enable = true;
      layout = [{
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }];
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/wlogout/style.css
      assertFileContent \
        home-files/.config/wlogout/layout \
        ${./layout-single-expected.json}
    '';
  };
}
