{ config, pkgs, ... }:

{
  programs.cava = {
    enable = true;

    package = config.lib.test.mkStubPackage { };

    settings = {
      general.framerate = 30;
      input.source = "alsa";
      smoothing.noise_reduction = 65;
      color = {
        background = "'#000000'";
        foreground = "'#ffffff'";
      };
    };
  };

  nmt.script = ''
    configFile=home-files/.config/cava/config
    assertFileExists $configFile
    assertFileContent $configFile ${./cava-basic-configuration-expected.ini}
  '';
}
