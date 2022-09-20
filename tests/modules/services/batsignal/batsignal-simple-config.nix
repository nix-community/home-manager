{ ... }:

{
  services.batsignal = {
    enable = true;
    warningLevelPercent = 15;
    criticalLevelPercent = 5;
    dangerLevelPercent = 2;
    fullLevelPercent = 90;
    warningLevelMessage = "Battery low";
    criticalLevelMessage = "Battery at critical level";
    fullLevelMessage = "Battery full";
    dangerLevelCommand = ''
      notify-send "Battery at danger level"
    '';
    batteryNames = [ "BAT0" "BAT1" ];
    updateIntervalSeconds = 120;
    appName = "Batsignal daemon";
    icon = "battery";
  };

  test.stubs.batsignal = { };

  nmt.script = ''
    assertFileContent \
      $(normalizeStorePaths home-files/.config/systemd/user/batsignal.service) \
      ${./batsignal-simple-config-expected.service}
  '';
}
