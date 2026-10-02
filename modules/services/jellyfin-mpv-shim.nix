{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) typeOf stringLength;
  jsonFormat = pkgs.formats.json { };
  cfg = config.services.jellyfin-mpv-shim;
  staticSettings = jsonFormat.generate "jellyfin-mpv-shim-conf" cfg.settings;

  renderOption =
    option:
    rec {
      int = toString option;
      float = int;
      bool = lib.hm.booleans.yesNo option;
      string = option;
    }
    .${typeOf option};

  renderOptionValue =
    value:
    let
      rendered = renderOption value;
      length = toString (stringLength rendered);
    in
    "%${length}%${rendered}";

  renderOptions = lib.generators.toKeyValue {
    mkKeyValue = lib.generators.mkKeyValueDefault { mkValueString = renderOptionValue; } "=";
    listsAsDuplicateKeys = true;
  };

  renderBindings =
    bindings: lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: "${name} ${value}") bindings);
in
{
  meta.maintainers = [ lib.maintainers.repparw ];

  options = {
    services.jellyfin-mpv-shim = {
      enable = lib.mkEnableOption "Jellyfin mpv shim";

      package = lib.mkPackageOption pkgs "jellyfin-mpv-shim" { };

      settings = lib.mkOption {
        inherit (jsonFormat) type;
        default = { };
        example = {
          allow_transcode_to_h265 = false;
          always_transcode = false;
          audio_output = "hdmi";
          auto_play = true;
          fullscreen = true;
          player_name = "mpv-shim";
        };
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/jellyfin-mpv-shim/conf.json`. See
          <https://github.com/jellyfin/jellyfin-mpv-shim#configuration>
          for the configuration documentation.

          Changed settings trigger a service restart when automatic systemd
          service switching is enabled. A running shim can write its old
          in-memory settings back between the merge and restart. Stop it before
          switching and start it afterward to avoid this window. If
          {option}`systemd.user.startServices` is `false` or `"suggest"`, restart
          the shim manually to load changed settings.
        '';
      };

      mpvConfig = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.attrsOf (
            lib.types.either lib.types.str (
              lib.types.either lib.types.int (lib.types.either lib.types.bool lib.types.float)
            )
          )
        );
        default = null;
        example = {
          profile = "gpu-hq";
          force-window = true;
        };
        description = ''
          mpv configuration options to use for jellyfin-mpv-shim.
          If null, jellyfin-mpv-shim will use its default mpv configuration.
        '';
      };

      mpvBindings = lib.mkOption {
        type = lib.types.nullOr (lib.types.attrsOf lib.types.str);
        default = null;
        example = {
          WHEEL_UP = "seek 10";
          WHEEL_DOWN = "seek -10";
        };
        description = ''
          mpv input bindings to use for jellyfin-mpv-shim.
          If null, jellyfin-mpv-shim will use its default input configuration.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.jellyfin-mpv-shim" pkgs lib.platforms.linux)
    ];

    xdg.configFile = {
      "jellyfin-mpv-shim/mpv.conf" = lib.mkIf (cfg.mpvConfig != null) {
        text = renderOptions cfg.mpvConfig;
      };

      "jellyfin-mpv-shim/input.conf" = lib.mkIf (cfg.mpvBindings != null) {
        text = renderBindings cfg.mpvBindings;
      };
    };

    systemd.user.services.jellyfin-mpv-shim = {
      Unit = {
        Description = "Jellyfin mpv shim";
        Documentation = "https://github.com/jellyfin/jellyfin-mpv-shim";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        X-Restart-Triggers = lib.mkIf (cfg.settings != { }) [ staticSettings ];
      };

      Service = {
        ExecStart = "${lib.getExe cfg.package}";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    # jellyfin-mpv-shim can't load the configuration file if it's not
    # writable. So we merge the settings defined here in Nix with the existing
    # configuration, if any.
    home.activation.jellyfinMpvShimSettingsActivation = lib.mkIf (cfg.settings != { }) (
      lib.hm.dag.entryBetween [ "reloadSystemd" ] [ "linkGeneration" ] (
        lib.hm.generators.mkImpureConfigMerger {
          inherit pkgs staticSettings;
          format = "json";
          empty = "{}";
          jqOperation = "$dynamic * $static";
          path = "${config.xdg.configHome}/jellyfin-mpv-shim/conf.json";
        }
      )
    );
  };
}
