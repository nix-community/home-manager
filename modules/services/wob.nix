{ config, lib, pkgs, ... }:

let
  inherit (lib)
    getExe literalExpression mkEnableOption mkIf mkOption mkPackageOption
    optional;

  cfg = config.services.wob;
  settingsFormat = pkgs.formats.ini { };

  configFile = settingsFormat.generate "wob.ini" cfg.settings;
in {
  meta.maintainers = with lib.maintainers; [ Scrumplex ];

  options.services.wob = {
    enable = mkEnableOption "wob";
    package = mkPackageOption pkgs "wob" { };

    settings = mkOption {
      type = settingsFormat.type;
      default = { };
      example = literalExpression ''
        {
          "" = {
            border_size = 10;
            height = 50;
          };
          "output.foo".name = "DP-1";
          "style.muted".background_color = "032cfc";
        }
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/wob/wob.ini`.
        See {manpage}`wob.ini(5)` for documentation.
      '';
    };

    systemd = mkEnableOption "systemd service and socket for wob"
      // mkOption { default = true; };

    systemdTarget = mkOption {
      type = lib.types.str;
      default = "graphical-session.target";
      example = "sway-session.target";
      description = ''
        The systemd target that will automatically start the Waybar service.

        When setting this value to `"sway-session.target"`,
        make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
        otherwise the service may never be started.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.wob" pkgs lib.platforms.linux)
    ];

    systemd.user = mkIf cfg.systemd {
      services.wob = {
        Unit = {
          Description =
            "A lightweight overlay volume/backlight/progress/anything bar for Wayland";
          Documentation = "man:wob(1)";
          PartOf = [ cfg.systemdTarget ];
          After = [ cfg.systemdTarget ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Service = {
          StandardInput = "socket";
          ExecStart = builtins.concatStringsSep " " ([ (getExe cfg.package) ]
            ++ optional (cfg.settings != { }) "--config ${configFile}");
        };
        Install.WantedBy = [ cfg.systemdTarget ];
      };

      sockets.wob = {
        Socket = {
          ListenFIFO = "%t/wob.sock";
          SocketMode = "0600";
          RemoveOnStop = "yes";
          FlushPending = "yes";
        };
        Install.WantedBy = [ "sockets.target" ];
      };
    };

    xdg.configFile."wob/wob.ini" =
      mkIf (cfg.settings != { }) { source = configFile; };
  };
}
