{
  services.hyprsunset = {
    enable = true;
    extraArgs = [ "--identity" ];

    settings = {
      max-gamma = 150;

      profile = [
        {
          time = "7:30";
          identity = true;
        }
        {
          time = "21:00";
          temperature = 5000;
          gamma = 0.8;
        }
      ];
    };
  };

  nmt.script = ''
    config=home-files/.config/hypr/hyprsunset.conf
    mainService=home-files/.config/systemd/user/hyprsunset.service
    assertFileExists $config
    assertFileExists $mainService
    assertFileContent $config ${./hyprsunset.conf}
  '';
}
