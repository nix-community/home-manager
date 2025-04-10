{
  services.hyprsunset = {
    enable = true;
    extraArgs = [ "--identity" ];

    transitions = {
      sunrise = {
        calendar = "*-*-* 06:30:00";
        requests = [
          [ "temperature 6500" ]
          [ "identity" ]
        ];
      };

      sunset = {
        calendar = "*-*-* 19:30:00";
        requests = [ [ "temperature 3500" ] ];
      };
    };
  };

  nmt.script = ''
    # Check that the main service exists
    mainService=home-files/.config/systemd/user/hyprsunset.service
    assertFileExists $mainService

    # Check that the transition services exist
    sunriseService=home-files/.config/systemd/user/hyprsunset-sunrise.service
    sunsetService=home-files/.config/systemd/user/hyprsunset-sunset.service
    assertFileExists $sunriseService
    assertFileExists $sunsetService

    # Check that the timers exist
    sunriseTimer=home-files/.config/systemd/user/hyprsunset-sunrise.timer
    sunsetTimer=home-files/.config/systemd/user/hyprsunset-sunset.timer
    assertFileExists $sunriseTimer
    assertFileExists $sunsetTimer

    # Verify timer configurations
    assertFileContains $sunriseTimer "OnCalendar=*-*-* 06:30:00"
    assertFileContains $sunsetTimer "OnCalendar=*-*-* 19:30:00"

    # Verify service configurations
    assertFileContains $sunriseService "ExecStart=@hyprland@/bin/hyprctl hyprsunset 'temperature 6500' && @hyprland@/bin/hyprctl hyprsunset identity"
    assertFileContains $sunsetService "ExecStart=@hyprland@/bin/hyprctl hyprsunset 'temperature 3500'"
  '';
}
