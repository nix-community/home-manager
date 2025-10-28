{ config, ... }:
{
  home.stateVersion = "22.11";

  programs.wleave = {
    package = config.lib.test.mkStubPackage { outPath = "@wleave@"; };
    enable = true;
    settings = {
      no-version-info = true;
      buttons-per-row = "3";

      buttons = [
        {
          label = "shutdown";
          action = "systemctl poweroff";
          text = "Shutdown";
          keybind = "s";
        }
        {
          label = "hibernate";
          action = "systemctl hibernate";
          text = "Hibernate";
          keybind = "h";
          height = 0.5;
          width = 0.5;
        }
        {
          label = "suspend";
          action = "systemctl suspend";
          text = "Suspend";
          keybind = "u";
          circular = true;
        }
        {
          label = "exit";
          action = "swaymsg exit";
          text = "Exit";
          keybind = "e";
        }
        {
          label = "reboot";
          action = "systemctl reboot";
          text = "Reboot";
          keybind = "r";
        }
        {
          label = "lock";
          action = "gtklock";
          text = "Lock";
          keybind = "l";
        }
      ];
    };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/wleave/style.css
    assertFileContent \
      home-files/.config/wleave/layout.json \
      ${./layout-multiple-expected.json}
  '';
}
