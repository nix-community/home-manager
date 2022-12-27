{ config, lib, pkgs, ... }:
let
  cfg = config.services.mpd-mpris;

  ignoreIfLocalMpd = value: if cfg.mpd.useLocal then null else value;

  renderArg = name: value:
    if lib.isBool value && value then
      "-${name}"
    else if lib.isInt value then
      "-${name} ${toString value}"
    else if lib.isString value then
      "-${name} ${lib.escapeShellArg value}"
    else
      "";

  concatArgs = strings:
    lib.concatStringsSep " " (lib.filter (s: s != "") strings);

  renderArgs = args: concatArgs (lib.mapAttrsToList renderArg args);

  renderCmd = pkg: args: "${pkg}/bin/mpd-mpris ${renderArgs args}";
in {
  meta.maintainers = [ lib.hm.maintainers.olmokramer ];

  options.services.mpd-mpris = {
    enable = lib.mkEnableOption
      "mpd-mpris: An implementation of the MPRIS protocol for MPD";

    package = lib.mkPackageOption pkgs "mpd-mpris" { };

    mpd = {
      useLocal = lib.mkOption {
        type = lib.types.bool;
        default = config.services.mpd.enable;
        defaultText = lib.literalExpression "config.services.mpd.enable";
        description = ''
          Whether to configure for the local MPD daemon. If
          <literal>true</literal> the <literal>network</literal>,
          <literal>host</literal>, and <literal>port</literal>
          settings are ignored.
        '';
      };

      network = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = ''
          The network used to dial to the MPD server. Check
          <link xlink:href="https://golang.org/pkg/net/#Dial" />
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

      password = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = ''
          The password to connect to MPD.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.mpd-mpris" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.mpd-mpris = {
      Install = { WantedBy = [ "default.target" ]; };

      Unit = {
        Description =
          "mpd-mpris: An implementation of the MPRIS protocol for MPD";
        After = [ "mpd.service" ];
        Requires = lib.mkIf cfg.mpd.useLocal [ "mpd.service" ];
      };

      Service = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "5s";
        ExecStart = renderCmd cfg.package {
          no-instance = true;
          network = ignoreIfLocalMpd cfg.mpd.network;
          host = ignoreIfLocalMpd cfg.mpd.host;
          port = ignoreIfLocalMpd cfg.mpd.port;
          pwd = cfg.mpd.password;
        };
      };
    };
  };
}
