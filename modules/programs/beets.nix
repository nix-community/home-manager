{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.beets;

  yamlFormat = pkgs.formats.yaml { };

in
{
  meta.maintainers = with lib.maintainers; [
    rycee
    Scrumplex
  ];

  options = {
    programs.beets = {
      enable = mkOption {
        type = types.bool;
        default =
          if lib.versionAtLeast config.home.stateVersion "19.03" then false else cfg.settings != { };
        defaultText = "false";
        description = ''
          Whether to enable the beets music library manager. This
          defaults to `false` for state
          version ≥ 19.03. For earlier versions beets is enabled if
          {option}`programs.beets.settings` is non-empty.
        '';
      };

      package = lib.mkPackageOption pkgs "beets" {
        example = "(pkgs.beets.override { pluginOverrides = { beatport.enable = false; }; })";
        extraDescription = ''
          Can be used to specify extensions.
        '';
      };

      settings = mkOption {
        type = yamlFormat.type;
        default = { };
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/beets/config.yaml`
        '';
      };

      mpdIntegration = {
        enableStats = lib.mkEnableOption "mpdstats plugin and service";

        enableUpdate = lib.mkEnableOption "mpdupdate plugin";

        host = mkOption {
          type = types.str;
          default = "localhost";
          example = "10.0.0.42";
          description = "The host that mpdstats will connect to.";
        };

        port = mkOption {
          type = types.port;
          default = config.services.mpd.network.port;
          defaultText = literalExpression "config.services.mpd.network.port";
          example = 6601;
          description = "The port that mpdstats will connect to.";
        };
      };
    };
  };

  config = lib.mkMerge [
    (mkIf cfg.enable {
      home.packages = [ cfg.package ];

      xdg.configFile."beets/config.yaml".source = yamlFormat.generate "beets-config" cfg.settings;
    })

    (mkIf (cfg.mpdIntegration.enableStats || cfg.mpdIntegration.enableUpdate) {
      programs.beets.settings.mpd = {
        host = cfg.mpdIntegration.host;
        port = cfg.mpdIntegration.port;
      };
    })

    (mkIf cfg.mpdIntegration.enableStats {
      programs.beets.settings.plugins = [ "mpdstats" ];
    })

    (mkIf cfg.mpdIntegration.enableUpdate {
      programs.beets.settings.plugins = [ "mpdupdate" ];
    })

    (mkIf (cfg.enable && cfg.mpdIntegration.enableStats) {
      systemd.user.services."beets-mpdstats" = {
        Unit = {
          Description = "Beets MPDStats daemon";
          After = lib.optional config.services.mpd.enable "mpd.service";
          Requires = lib.optional config.services.mpd.enable "mpd.service";
        };
        Service.ExecStart = "${cfg.package}/bin/beet mpdstats";
        Install.WantedBy = [ "default.target" ];
      };
    })
  ];
}
