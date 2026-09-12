{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.mpd-mpris;
in
{
  meta.maintainers = [ lib.hm.maintainers.olmokramer ];

  imports = [
    (lib.mkRemovedOptionModule [ "services" "mpd-mpris" "mpd" "useLocal" ] ''
      Just don't configure the network settings and it should automatically
      connect to the local MPD server.
    '')

    (lib.mkRenamedOptionModule
      [ "services" "mpd-mpris" "mpd" "network" ]
      [ "services" "mpd-mpris" "settings" "network" ]
    )

    (lib.mkRenamedOptionModule
      [ "services" "mpd-mpris" "mpd" "host" ]
      [ "services" "mpd-mpris" "settings" "host" ]
    )

    (lib.mkRenamedOptionModule
      [ "services" "mpd-mpris" "mpd" "port" ]
      [ "services" "mpd-mpris" "settings" "port" ]
    )

    (lib.mkRemovedOptionModule [ "services" "mpd-mpris" "mpd" "password" ] ''
      Use `services.mpd-mpris.settings.pwd-file` instead, which will not
      write your password to the world readable nix store.
    '')
  ];

  options.services.mpd-mpris = {
    enable = lib.mkEnableOption "mpd-mpris: An implementation of the MPRIS protocol for MPD";

    package = lib.mkPackageOption pkgs "mpd-mpris" { };

    settings = lib.mkOption {
      type = lib.types.submodule (settings: {
        freeformType =
          with lib.types;
          attrsOf (
            nullOr (oneOf [
              bool
              int
              str
            ])
          );

        options = {
          instance-name = lib.mkOption {
            type = with lib.types; nullOr str;
            default = null;
            description = ''
              Name of the MPRIS instance. Leave at `null` to set the
              `-no-instance` flag.
            '';
          };

          no-instance = lib.mkOption {
            type = with lib.types; nullOr bool;
            default = if settings.config.instance-name == null then true else null;
            description = ''
              Whether to pass the `-no-instance` flag. Automatically enabled if
              `instance-name` is not set.
            '';
          };

          network = lib.mkOption {
            type = with lib.types; nullOr str;
            default = null;
            description = ''
              The network used to dial to the MPD server. Check <https://golang.org/pkg/net/#Dial>
              for available values (most common are "tcp" and "unix")
            '';
          };

          host = lib.mkOption {
            type = with lib.types; nullOr str;
            default = null;
            example = "192.168.1.1";
            description = "The address where MPD is listening for connections.";
          };

          port = lib.mkOption {
            type = with lib.types; nullOr port;
            default = null;
            description = ''
              The port number where MPD is listening for connections.
            '';
          };

          pwd-file = lib.mkOption {
            type = with lib.types; nullOr path;
            default = null;
            description = ''
              Path to a file containing the password to connect to MPD.
            '';
          };
        };
      });
      default = { };
      description = "Options to be set on the command line.";
      example = {
        instance-name = "desktop";
        port = 9876;
        pwd-file = "/home/me/passwords/mpd";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.mpd-mpris" pkgs lib.platforms.linux)

      (
        let
          inherit (cfg.settings) port network;
        in
        {
          assertion = port != null -> network == null || network == "tcp";
          message = ''
            `services.mpd-mpris.port` can only be specified when `services.mpd-mpris.network`
            is 'tcp' (the default), but network has value: '${network}'
          '';
        }
      )
    ];

    systemd.user.services.mpd-mpris = {
      Install = {
        WantedBy = [ "default.target" ];
      };

      Unit = {
        Description = "mpd-mpris: An implementation of the MPRIS protocol for MPD";
        After = lib.mkIf (cfg.settings.host == "") [ "mpd.service" ];
        Requires = lib.mkIf (cfg.settings.host == "") [ "mpd.service" ];
      };

      Service = {
        Type = "dbus";
        Restart = "on-failure";
        RestartSec = "5s";

        BusName =
          let
            base = "org.mpris.MediaPlayer2.mpd";
            name = cfg.settings.instance-name;
          in
          if name == null then base else "${base}.${name}";

        ExecStart =
          let
            optionFormat = optionName: {
              option = "-${optionName}";
              sep = null;
              explicitBool = false;
            };

            flags = lib.cli.toCommandLine optionFormat cfg.settings;
          in
          lib.escapeShellArgs ([ (lib.getExe cfg.package) ] ++ flags);
      };
    };
  };
}
