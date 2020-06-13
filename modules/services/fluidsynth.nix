{ config, lib, pkgs, ... }:

with lib;

let
  name = "fluidsynth";
  cfg = config.services.fluidsynth;
in {
  meta.maintainers = [ maintainers.valodim ];

  ###### interface
  options = {
    services.fluidsynth = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable fluidsynth, the music player daemon.
        '';
      };

      soundFont = mkOption {
        type = types.path;
        default = "${pkgs.soundfont-fluid}/share/soundfonts/FluidR3_GM2-2.sf2";
        description = ''
          The soundfont file to use, in SoundFont 2 format.
        '';
      };

      extraOptions = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "--sample-rate 96000" ];
        description = ''
          Extra arguments, added verbatim to the fluidsynth command.
          <citerefentry>
            <refentrytitle>fluidsynth.conf</refentrytitle>
            <manvolnum>1</manvolnum>
          </citerefentry>.
        '';
      };
    };
  };

  ###### implementation
  config = mkIf cfg.enable {
    systemd.user.services.fluidsynth = {
      Unit = {
        Description = "FluidSynth Daemon";
        Documentation = "man:fluidsynth(1)";
        BindsTo = [ "pulseaudio.service" ];
        After = [ "pulseaudio.service" ];
      };
      Install = { WantedBy = [ "default.target" ]; };
      Service = {
        ExecStart = "${pkgs.fluidsynth}/bin/fluidsynth -a pulseaudio -si ${
            lib.concatStringsSep " " cfg.extraOptions
          } ${cfg.soundFont}";
      };
    };
  };
}
