{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.pasystray;

in {
  meta.maintainers = [ hm.maintainers.pltanton ];

  options = {
    services.pasystray = {
      enable = mkEnableOption "PulseAudio system tray";

      extraOptions = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Extra command-line arguments to pass to {command}`pasystray`.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.pasystray" pkgs platforms.linux)
    ];

    systemd.user.services.pasystray = {
      Unit = {
        Description = "PulseAudio system tray";
        Requires = [ "tray.target" ];
        After = [ "graphical-session-pre.target" "tray.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        Environment =
          let toolPaths = makeBinPath [ pkgs.paprefs pkgs.pavucontrol ];
          in [ "PATH=${toolPaths}" ];
        ExecStart = escapeShellArgs
          ([ "${pkgs.pasystray}/bin/pasystray" ] ++ cfg.extraOptions);
      };
    };
  };
}
