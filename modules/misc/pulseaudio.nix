{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.pulseaudio;

in

{
  options.pulseaudio = {
    network = {
      discoverPulseAudio = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Make discoverable PulseAudio network sound devices available locally
        '';
      };

      discoverAirTunes = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Make discoverable Apple AirTunes sound devices available locally
        '';
      };
    };
  };

  config = {
    dconf.settings."org/freedesktop/pulseaudio/module-groups/zeroconf-discover" = mkIf cfg.network.discoverPulseAudio {
      enabled = true;
      args0 = "";
      name0 = "module-zeroconf-discover";
    };
    dconf.settings."org/freedesktop/pulseaudio/module-groups/raop-discover" = mkIf cfg.network.discoverAirTunes {
      enabled = true;
      args0 = "";
      name0 = "module-raop-discover";
    };
  };
}
