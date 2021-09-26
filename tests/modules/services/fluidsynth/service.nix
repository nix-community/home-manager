{ config, pkgs, ... }: {
  config = {
    services.fluidsynth.enable = true;
    services.fluidsynth.soundService = "pipewire-pulse";
    services.fluidsynth.soundFont = "/path/to/soundFont";
    services.fluidsynth.extraOptions = [ "--sample-rate 96000" ];

    test.stubs.fluidsynth = { };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/fluidsynth.service

      assertFileExists $serviceFile

      assertFileContains $serviceFile \
        'ExecStart=@fluidsynth@/bin/fluidsynth -a pulseaudio -si --sample-rate 96000 /path/to/soundFont'

      assertFileContains $serviceFile \
        'After=pipewire-pulse.service'

      assertFileContains $serviceFile \
        'BindsTo=pipewire-pulse.service'
    '';
  };
}
