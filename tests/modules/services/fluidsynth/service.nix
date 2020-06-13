{ config, pkgs, ... }: {
  config = {
    services.fluidsynth.enable = true;
    services.fluidsynth.soundFont = "/path/to/soundFont";
    services.fluidsynth.extraOptions = [ "--sample-rate 96000" ];

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/fluidsynth.service

      assertFileExists $serviceFile

      assertFileRegex $serviceFile 'ExecStart=.*/bin/fluidsynth.*--sample-rate 96000.*/path/to/soundFont'
    '';
  };
}
