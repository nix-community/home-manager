{ pkgs, ... }:
{
  services.protonmail-bridge = {
    enable = true;
    package = pkgs.protonmail-bridge-gui;
    extraPackages = with pkgs; [
      gnome-keyring
    ];
    logLevel = "info";
  };

  nmt.script = ''
    local service="home-files/.config/systemd/user/protonmail-bridge.service"

    assertFileExists $service
    assertFileRegex $service 'Environment=PATH=.*gnome-keyring.*'
    assertFileRegex $service 'ExecStart=.*/protonmail-bridge-gui --noninteractive --log-level info'
  '';
}
