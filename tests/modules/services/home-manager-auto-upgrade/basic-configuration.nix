{ config, ... }:

{
  config = {
    services.home-manager.autoUpgrade = {
      enable = true;
      frequency = "00:00";
    };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/home-manager-auto-upgrade.service
      assertFileExists $serviceFile

      timerFile=home-files/.config/systemd/user/home-manager-auto-upgrade.timer
      assertFileExists $timerFile
    '';
  };
}
