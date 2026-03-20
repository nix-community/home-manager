{ config, ... }:
{
  config = {
    home.stateVersion = "22.11";

    programs.wleave = {
      package = config.lib.test.mkStubPackage { outPath = "@wleave@"; };
      enable = true;
      settings.buttons = [
        {
          label = "shutdown";
          action = "systemctl poweroff";
          text = "Shutdown";
          keybind = "s";
        }
      ];
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/wleave/style.css
      assertFileContent \
        home-files/.config/wleave/layout.json \
        ${./layout-single-expected.json}
    '';
  };
}
