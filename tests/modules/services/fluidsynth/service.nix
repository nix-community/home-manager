{ config, pkgs, ... }: {
  config = {
    services.fluidsynth.enable = true;
    services.fluidsynth.soundFont = "/path/to/soundFont";
    services.fluidsynth.extraOptions = [ "--sample-rate 96000" ];

    nixpkgs.overlays = [
      (self: super: {
        fluidsynth = pkgs.writeScriptBin "dummy-fluidsynth" "" // {
          outPath = "@fluidsynth@";
        };
      })
    ];

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/fluidsynth.service

      assertFileExists $serviceFile

      assertFileContains $serviceFile \
        'ExecStart=@fluidsynth@/bin/fluidsynth -a pulseaudio -si --sample-rate 96000 /path/to/soundFont'
    '';
  };
}
