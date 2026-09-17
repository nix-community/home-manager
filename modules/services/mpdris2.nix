{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.mpdris2;

  toIni = lib.generators.toINI {
    mkKeyValue =
      key: value:
      let
        value' = if lib.isBool value then (if value then "True" else "False") else toString value;
      in
      "${key} = ${value'}";
  };
in
{
  imports =
    lib.hm.deprecations.mkSettingsRenamedOptionModules
      [ "services" "mpdris2" ]
      [ "services" "mpdris2" "settings" ]
      { priority = 1400; }
      [
        {
          old = "notifications";
          new = [
            "Bling"
            "notify"
          ];
          fallback = false;
        }
        {
          old = "multimediaKeys";
          new = [
            "Bling"
            "mmkeys"
          ];
          fallback = false;
        }
        {
          old = [
            "mpd"
            "host"
          ];
          new = [
            "Connection"
            "host"
          ];
        }
        {
          old = [
            "mpd"
            "port"
          ];
          new = [
            "Connection"
            "port"
          ];
        }
        {
          old = [
            "mpd"
            "password"
          ];
          new = [
            "Connection"
            "password"
          ];
        }
      ]
    ++ [
      (lib.hm.deprecations.mkSettingsChangedOptionModule {
        from = [
          "services"
          "mpdris2"
          "mpd"
          "musicDirectory"
        ];
        to = [
          "services"
          "mpdris2"
          "settings"
        ];
        key = "Library";
        priority = 100;
        oldOption = {
          type = lib.types.nullOr lib.types.path;
          default = config.services.mpd.musicDirectory;
        };
        convert = value: {
          music_dir = lib.mkOverride 1400 (if value == null then null else toString value);
        };
      })
    ];

  meta.maintainers = [ lib.maintainers.pjones ];

  options.services.mpdris2 = {
    enable = lib.mkEnableOption "mpDris2 the MPD to MPRIS2 bridge";

    settings = lib.mkOption {
      inherit ((pkgs.formats.ini { })) type;
      default = { };
      example = {
        Library.cover_regex = "^(album|cover).*$";
        Notify = {
          timeout = 5000;
          urgency = 1;
          summary = "%artist% - %title%";
        };
      };
      description = ''
        Configuration settings for mpDris2. The settings are written to
        {file}`$XDG_CONFIG_HOME/mpDris2/mpDris2.conf`.

        See <https://github.com/eonpatapon/mpDris2/blob/master/src/mpDris2.conf>
        for available settings.
      '';
    };

    package = lib.mkPackageOption pkgs "mpdris2" { };
  };

  config = lib.mkIf cfg.enable {
    services.mpdris2.settings = {
      Connection = {
        host = lib.mkOptionDefault config.services.mpd.network.listenAddress;
        port = lib.mkOptionDefault config.services.mpd.network.port;
      };
      Library.music_dir = lib.mkOptionDefault (
        if config.services.mpd.musicDirectory == null then
          null
        else
          toString config.services.mpd.musicDirectory
      );
      Bling = {
        notify = lib.mkOptionDefault false;
        mmkeys = lib.mkOptionDefault false;
      };
    };

    assertions = [
      (lib.hm.assertions.assertPlatform "services.mpdris2" pkgs lib.platforms.linux)
    ];

    xdg.configFile."mpDris2/mpDris2.conf".text = toIni (
      lib.mapAttrs (
        section:
        lib.filterAttrs (key: value: !(section == "Connection" && key == "password" && value == null))
      ) cfg.settings
    );

    systemd.user.services.mpdris2 = {
      Install = {
        WantedBy = [ "default.target" ];
      };

      Unit = {
        Description = "MPRIS 2 support for MPD";
        After = [ "mpd.service" ];
      };

      Service = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "5s";
        ExecStart = "${cfg.package}/bin/mpDris2";
        BusName = "org.mpris.MediaPlayer2.mpd";
      };
    };
  };
}
