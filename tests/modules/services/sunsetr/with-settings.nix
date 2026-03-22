{ config, ... }:

let
  inherit (config.lib.test) mkStubPackage;

  expectedConfig = builtins.toFile "expected.toml" ''
    backend = "auto"
    day_gamma = 100
    day_temp = 6500
    latitude = 43.0
    longitude = -7.566667
    night_gamma = 90
    night_temp = 3300
    smoothing = true
    startup_duration = 1
    transition_duration = 45
    transition_mode = "geo"
    update_interval = 60
  '';

  expectedService = builtins.toFile "expected.service" ''
    [Install]
    WantedBy=graphical-session.target

    [Service]
    ExecStart=@sunsetr@/bin/sunsetr
    Restart=on-failure
    Slice=background.slice
    TimeoutStopSec=5

    [Unit]
    BindsTo=graphical-session.target
    Description=Automatic blue light filter for Wayland
    PartOf=graphical-session.target
  '';
in
{
  services.sunsetr = {
    enable = true;
    package = mkStubPackage {
      name = "sunsetr";
      outPath = "@sunsetr@";
    };
    settings = {
      backend = "auto";
      smoothing = true;
      startup_duration = 1;
      night_temp = 3300;
      day_temp = 6500;
      night_gamma = 90;
      day_gamma = 100;
      update_interval = 60;
      transition_mode = "geo";
      transition_duration = 45;
      latitude = 43.0;
      longitude = -7.566667;
    };
  };

  nmt.script = ''
    configFile=home-files/.config/sunsetr/sunsetr.toml
    serviceFile=home-files/.config/systemd/user/sunsetr.service

    assertFileExists $configFile
    assertFileContent $configFile ${expectedConfig}

    assertFileExists $serviceFile
    assertFileContent $serviceFile ${expectedService}
  '';
}
