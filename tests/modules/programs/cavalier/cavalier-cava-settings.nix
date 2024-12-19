{ config, pkgs, ... }:

{
  programs.cavalier = {
    enable = true;

    package = config.lib.test.mkStubPackage { };

    settings.cava = {
      general = {
        framerate = 60;
        bars = 12;
        autosens = 1;
        sensitivity = 100;
      };
      input = { method = "pulse"; };
      output = {
        method = "raw";
        raw_target = "/dev/stdout";
        bit_format = "16bit";
        channels = "stereo";
      };
      smoothing = {
        monstercat = 1;
        noise_reduction = 77;
      };
    };
  };

  nmt.script = ''
    configFile="home-files/.config/Nickvision Cavalier/cava_config"
    assertFileExists "$configFile"
    assertFileContent "$configFile" ${./cavalier-cava-settings-expected.ini}
  '';
}
