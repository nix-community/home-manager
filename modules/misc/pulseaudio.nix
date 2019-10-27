{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.pulseaudio;

in

{
  options.pulseaudio = {
    enable = mkEnableOption "pulseaudio";
    
    discoverPulseAudio = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Make discoverable PulseAudio network sound devices available locally.
      '';
    };

    discoverAirTunes = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Make discoverable Apple AirTunes sound devices available locally.
      '';
    };
    
    remoteAccess = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Enable network acces to local sound devices.
        '';
      };
      
      allowRemoteDiscover = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Allow other machines on the LAN to discover local sound devices.
        '';
      };

      requireAuthentication = mkOption {
        default = true;
        type = types.bool;
        description = ''
            Require authentication.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    dconf.settings = {
      "org/freedesktop/pulseaudio/module-groups/zeroconf-discover" =
        {
          enabled = cfg.discoverPulseAudio;
          args0 = "";
          name0 = "module-zeroconf-discover";
        };

      "org/freedesktop/pulseaudio/module-groups/raop-discover" =
        {
          enabled = cfg.discoverAirTunes;
          args0 = "";
          name0 = "module-raop-discover";
        };

      "org/freedesktop/pulseaudio/module-groups/remote-access" =
        let
          authArg = if cfg.remoteAccess.requireAuthentication then "" else "auth-anonymous=1";
        in
          mkMerge [
            {
              enabled = cfg.remoteAccess.enable;
              args0 = authArg;
              args1 = authArg;
              name0 = "module-native-protocol-tcp";
              name1 = "module-esound-protocol-tcp";
            }
            
            (mkIf cfg.remoteAccess.allowRemoteDiscover {
              "org/freedesktop/pulseaudio/module-groups/remote-access".args2 = "";
              "org/freedesktop/pulseaudio/module-groups/remote-access".name2 = "module-zeroconf-publish";
            })
          ];
    };
  };
}
