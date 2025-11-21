{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    ;

  cfg = config.services.shpool;
  format = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.maintainers; [ fredeb ];

  options.services.shpool = {
    enable = mkEnableOption "shpool";
    package = mkPackageOption pkgs "shpool" { nullable = true; };

    settings = lib.mkOption {
      type = format.type;
      default = { };
      example = {
        prompt_prefix = "[$SHPOOL_SESSION_NAME]";
        session_restore_mode.lines = 1000;

        keybinding = [
          {
            binding = "Ctrl-a d";
            action = "detach";
          }
        ];

        motd = "never";
      };
      description = ''
        Configuration to use for shpool. See
        <https://github.com/shell-pool/shpool/blob/master/CONFIG.md>
        for available options.
      '';
    };

    systemd = mkEnableOption "systemd service and socket for shpool" // mkOption { default = true; };
  };

  config = mkIf cfg.enable {

    systemd.user = {
      services.shpool = {
        Unit = {
          Description = "Shpool - Shell Session Pool";
          Requires = [ "shpool.socket" ];
        };

        Service = {
          Type = "simple";
          ExecStart = "${getExe cfg.package} daemon";
          KillMode = "mixed";
          TimeoutStopSec = "2s";
          SendSIGHUP = true;
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      sockets.shpool = {
        Unit = {
          Description = "Shpool Shell Session Pooler";
        };

        Socket = {
          ListenStream = "%t/shpool/shpool.socket";
          SocketMode = "0600";
          RemoveOnStop = "yes";
          FlushPending = "yes";
        };
        Install = {
          WantedBy = [ "sockets.target" ];
        };
      };
    };

    home.packages = [ cfg.package ];

    xdg.configFile = lib.mkIf (cfg.settings != { }) {
      "shpool/config.toml".source = format.generate "config.toml" cfg.settings;
    };
  };
}
