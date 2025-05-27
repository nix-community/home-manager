{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.pasystray;

in
{
  meta.maintainers = [ lib.hm.maintainers.pltanton ];

  options = {
    services.pasystray = {
      enable = lib.mkEnableOption "PulseAudio system tray";

      extraOptions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Extra command-line arguments to pass to {command}`pasystray`.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.pasystray" pkgs lib.platforms.linux)
    ];

    systemd.user.services.pasystray = {
      Unit = {
        Description = "PulseAudio system tray";
        Requires = [ "tray.target" ];
        After = [
          "graphical-session.target"
          "tray.target"
        ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        Environment =
          let
            toolPaths = lib.makeBinPath [
              pkgs.paprefs
              pkgs.pavucontrol
            ];
          in
          [ "PATH=${toolPaths}" ];
        ExecStart = lib.escapeShellArgs ([ "${pkgs.pasystray}/bin/pasystray" ] ++ cfg.extraOptions);
      };
    };
  };
}
