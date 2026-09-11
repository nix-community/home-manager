{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.services.copyq;

  iniFormat = pkgs.formats.ini { };

in
{
  meta.maintainers = [ lib.maintainers.DPDmancul ];

  options.services.copyq = {
    enable = lib.mkEnableOption "CopyQ, a clipboard manager with advanced features";

    package = lib.mkPackageOption pkgs "copyq" { };

    systemdTarget = lib.mkOption {
      type = lib.types.str;
      default = "graphical-session.target";
      example = "sway-session.target";
      description = ''
        The systemd target that will automatically start the CopyQ service.

        When setting this value to `"sway-session.target"`,
        make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
        otherwise the service may never be started.
      '';
    };

    forceXWayland = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = "Force the CopyQ to use the X backend on wayland";
    };

    settings = lib.mkOption {
      type = iniFormat.type.nestedTypes.elemType;
      default = { };
      description = "Copyq configuration. Run `copyq config` to list available options.";
      example = lib.literalExpression ''
        {
          disable_tray = true;
          hide_main_window = true;
          hide_tabs = true;
          hide_toolbar = true;
          autostart = false;
        }
      '';
    };
  };

  config =
    let

      executablePath = lib.meta.getExe cfg.package;

    in
    lib.mkIf cfg.enable {
      assertions = [
        (lib.hm.assertions.assertPlatform "services.copyq" pkgs lib.platforms.linux)
      ];

      home.packages = [ cfg.package ];

      systemd.user.services.copyq = {
        Unit = {
          Description = "CopyQ clipboard management daemon";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = executablePath;
          Restart = "on-failure";
          Environment = lib.optional cfg.forceXWayland "QT_QPA_PLATFORM=xcb";
        };

        Install = {
          WantedBy = [ cfg.systemdTarget ];
        };
      };

      home.activation.copyqConfig = lib.mkIf (cfg.settings != { }) (
        lib.hm.dag.entryAfter [ "writeBoundary" ] (
          lib.concatLines (
            lib.mapAttrsToList (
              k: v:
              "run --quiet ${
                lib.escapeShellArgs [
                  executablePath
                  "--start-server"
                  "config"
                  k
                  (if lib.isBool v then lib.boolToString v else toString v)
                ]
              } 2> >(grep -v '^Warning: CopyQ server is already running' >&2)"
            ) cfg.settings
          )
        )
      );
    };
}
