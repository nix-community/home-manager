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

    (lib.mkRemovedOptionModule [ "services" "mpd-mpris" "mpd" "password" ] ''
      Use `services.mpd-mpris.settings.pwd-file` instead, which will not
      write your password to the world readable nix store.
    '')
  ]
  ++ (lib.hm.deprecations.mkSettingsRenamedOptionModules
    [ "services" "mpd-mpris" "mpd" ]
    [ "services" "mpd-mpris" "settings" ]
    { transform = x: x; }
    [
      "network"
      "host"
      "port"
    ]
  );

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
            type = with lib.types; nullOr (either str path);
            default = null;
            example = "/run/secrets/mpd";
            description = ''
              Path to a file containing the password to connect to MPD.
            '';
          };
        };
      });
      default = { };
      description = ''
        Options to be set on the command line.

        These options are written to the world-readable Nix store as part of
        the systemd unit, so avoid setting the MPD password with `pwd` here.
        Use [](#opt-services.mpd-mpris.settings.pwd-file) instead, which
        mpd-mpris reads when it starts.
      '';
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
              formatArg =
                value:
                if lib.hm.strings.isPathLike value then
                  toString value
                else
                  lib.generators.mkValueStringDefault { } value;
            };

            flags = lib.cli.toCommandLine optionFormat cfg.settings;
          in
          lib.escapeShellArgs ([ (lib.getExe cfg.package) ] ++ flags);
      };
    };
  };
}
