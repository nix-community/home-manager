{ pkgs, ... }:

{
  services.hypridle = {
    enable = true;
    package = pkgs.hypridle;

    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        ignore_dbus_inhibit = false;
        lock_cmd = "hyprlock";
      };

      listener = [
        {
          timeout = 900;
          on-timeout = "hyprlock";
        }
        {
          timeout = 1200;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  test.stubs.hypridle = { };

  nmt.script = ''
    config=home-files/.config/hypr/hypridle.conf
    clientServiceFile=home-files/.config/systemd/user/hypridle.service
    assertFileExists $config
    assertFileExists $clientServiceFile
    assertFileContent $config ${./hypridle.conf}
  '';
}
