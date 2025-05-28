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
  meta.maintainers = [ lib.hm.maintainers.repparw ];

  options = {
    services.jellyfin-mpv-shim = {
      enable = lib.mkEnableOption "Jellyfin mpv shim";

      package = lib.mkPackageOption pkgs "jellyfin-mpv-shim" { };

      settings = lib.mkOption {
        type = jsonFormat.type;
        default = { };
        example = lib.literalExpression ''
          {
            allow_transcode_to_h265 = false;
            always_transcode = false;
            audio_output = "hdmi";
            auto_play = true;
            fullscreen = true;
            player_name = "mpv-shim";
          }
        '';
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/jellyfin-mpv-shim/conf.json`. See
          <https://github.com/jellyfin/jellyfin-mpv-shim#configuration>
          for the configuration documentation.
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
        example = lib.literalExpression ''
          {
                    profile = "gpu-hq";
                    force-window = true;
                  }'';
        description = ''
          mpv configuration options to use for jellyfin-mpv-shim.
          If null, jellyfin-mpv-shim will use its default mpv configuration.
        '';
      };

      mpvBindings = lib.mkOption {
        type = lib.types.nullOr (lib.types.attrsOf lib.types.str);
        default = null;
        example = lib.literalExpression ''
          {
                    WHEEL_UP = "seek 10";
                    WHEEL_DOWN = "seek -10";
                  }'';
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
      "jellyfin-mpv-shim/conf.json" = lib.mkIf (cfg.settings != { }) {
        source = jsonFormat.generate "jellyfin-mpv-shim-conf" cfg.settings;
      };

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
      };

      Service = {
        ExecStart = "${lib.getExe cfg.package}";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
