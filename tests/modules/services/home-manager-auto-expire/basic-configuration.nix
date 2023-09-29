{ ... }:

{
  config = {
    services.home-manager.autoExpire = {
      enable = true;
      timestamp = "-7 days";
      frequency = "00:00";
      cleanup.store = true;
    };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/home-manager-auto-expire.service
      assertFileExists $serviceFile

      timerFile=home-files/.config/systemd/user/home-manager-auto-expire.timer
      assertFileExists $timerFile
    '';
  };
}
