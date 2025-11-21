{ config, ... }:
{
  services.hypridle.enable = true;
  programs.hyprpanel = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "hyprpanel"; };
    settings = {
      bar.battery.label = true;
      bar.bluetooth.label = false;
      bar.clock.format = "%H:%M:%S";
      bar.layouts = {
        "*" = {
          left = [
            "dashboard"
            "workspaces"
            "media"
          ];
          middle = [ "windowtitle" ];
          right = [
            "volume"
            "network"
            "bluetooth"
            "notifications"
          ];
        };
      };
    };
  };

  nmt.script = ''
    assertFileContent \
      "home-files/.config/hyprpanel/config.json" \
      ${./with-hypridle.json}
  '';
}
