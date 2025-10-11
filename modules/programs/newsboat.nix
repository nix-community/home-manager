{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;

  cfg = config.programs.newsboat;
  wrapQuote = x: ''"${x}"'';

  urlsFileContents =
    let
      mkUrlEntry =
        u:
        lib.concatStringsSep " " (
          [ u.url ] ++ map wrapQuote u.tags ++ lib.optional (u.title != null) (wrapQuote "~${u.title}")
        );
      urls = map mkUrlEntry cfg.urls;

      mkQueryEntry = n: v: ''"query:${n}:${lib.escape [ ''"'' ] v}"'';
      queries = lib.mapAttrsToList mkQueryEntry cfg.queries;
    in
    lib.concatStringsSep "\n" (
      if lib.versionAtLeast config.home.stateVersion "20.03" then queries ++ urls else urls ++ queries
    )
    + "\n";

  configFileContents = ''
    max-items ${toString cfg.maxItems}
    browser ${cfg.browser}
    reload-threads ${toString cfg.reloadThreads}
    auto-reload ${lib.hm.booleans.yesNo cfg.autoReload}
    ${lib.optionalString (cfg.reloadTime != null) (toString "reload-time ${toString cfg.reloadTime}")}
    prepopulate-query-feeds yes

    ${cfg.extraConfig}
  '';

in
{
  meta.maintainers = [ lib.maintainers.sumnerevans ];

  options = {
    programs.newsboat = {
      enable = lib.mkEnableOption "the Newsboat feed reader";

      package = lib.mkPackageOption pkgs "newsboat" { nullable = true; };

      urls = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              url = mkOption {
                type = types.str;
                example = "http://example.com";
                description = "Feed URL.";
              };

              tags = mkOption {
                type = types.listOf types.str;
                default = [ ];
                example = [
                  "foo"
                  "bar"
                ];
                description = "Feed tags.";
              };

              title = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "ORF News";
                description = "Feed title.";
              };
            };
          }
        );
        default = [ ];
        example = [
          {
            url = "http://example.com";
            tags = [
              "foo"
              "bar"
            ];
          }
        ];
        description = ''
          List of news feeds. Leave it empty if you want to manage feeds
          imperatively, for example, using Syncthing.
        '';
      };

      maxItems = mkOption {
        type = types.int;
        default = 0;
        description = "Maximum number of items per feed, 0 for infinite.";
      };

      reloadThreads = mkOption {
        type = types.int;
        default = 5;
        description = "How many threads to use for updating the feeds.";
      };

      autoReload = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable automatic reloading while newsboat is running.
        '';
      };

      reloadTime = mkOption {
        type = types.nullOr types.int;
        default = 60;
        description = "Time in minutes between reloads.";
      };

      browser = mkOption {
        type = types.str;
        default = "${pkgs.xdg-utils}/bin/xdg-open";
        defaultText = lib.literalExpression "\${pkgs.xdg-utils}/bin/xdg-open";
        description = "External browser to use.";
      };

      queries = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = {
          "foo" = ''rssurl =~ "example.com"'';
        };
        description = "A list of queries to use.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra configuration values that will be appended to the end.
        '';
      };

      autoFetchArticles = {
        enable = lib.mkEnableOption "automatic article fetcher timer";

        onCalendar = lib.mkOption {
          type = lib.types.str;
          default = "daily";
          example = "weekly";
          description = ''
            How often to fetch new articles.

            See {manpage}`systemd.time(7)` for more information about the format.
          '';
        };
      };

      autoVacuum = {
        enable = lib.mkEnableOption "automatic cleaning of the newsboat cache";

        onCalendar = lib.mkOption {
          type = lib.types.str;
          default = "weekly";
          example = "monthly";
          description = ''
            How often to run the cleaning command.

            See {manpage}`systemd.time(7)` for more information about the format.
          '';
        };
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.queries != { } -> cfg.urls != [ ];
        message = ''
          Cannot specify queries if urls is empty. Unset queries if you
          want to manage urls imperatively.
        '';
      }
      {
        assertion = cfg.autoFetchArticles.enable -> cfg.package != null;
        message = ''
          Cannot fetch articles if package is unset.
        '';
      }
      {
        assertion = cfg.autoVacuum.enable -> cfg.package != null;
        message = ''
          Cannot clean newsboat cache if package is unset.
        '';
      }
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    # Use ~/.newsboat on stateVersion < 21.05 and use ~/.config/newsboat for
    # stateVersion >= 21.05.
    home.file = mkIf (lib.versionOlder config.home.stateVersion "21.05") {
      ".newsboat/urls" = mkIf (cfg.urls != [ ]) { text = urlsFileContents; };
      ".newsboat/config".text = configFileContents;
    };
    xdg.configFile = mkIf (lib.versionAtLeast config.home.stateVersion "21.05") {
      "newsboat/urls" = mkIf (cfg.urls != [ ]) { text = urlsFileContents; };
      "newsboat/config".text = configFileContents;
    };

    systemd.user.services.newsboat-fetch-articles = lib.mkIf cfg.autoFetchArticles.enable {
      Unit = {
        Description = "Automatic Newsboat Article Fetcher";
        Documentation = [ "man:newsboat(1)" ];
      };

      Service = {
        Type = "oneshot";
        Slice = "background.slice";
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        RuntimeDirectory = "newsboat";
        ExecStart = "${lib.getExe pkgs.flock} %t/newsboat.lock ${lib.getExe cfg.package} --execute=reload";
      };
    };

    systemd.user.timers.newsboat-fetch-articles = lib.mkIf cfg.autoFetchArticles.enable {
      Unit = {
        Description = "Automatic Newsboat Article Fetcher";
        Documentation = [ "man:newsboat(1)" ];
        After = [ "network.target" ];
      };

      Timer = {
        Unit = "newsboat-fetch-articles.service";
        OnCalendar = cfg.autoFetchArticles.onCalendar;
        Persistent = true;
      };

      Install = {
        WantedBy = [ "timers.target" ];
      };
    };

    systemd.user.services.newsboat-vacuum = lib.mkIf cfg.autoVacuum.enable {
      Unit = {
        Description = "Automatic Newsboat Cache Cleaner";
        Documentation = [ "man:newsboat(1)" ];
      };

      Service = {
        Type = "oneshot";
        Slice = "background.slice";
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        RuntimeDirectory = "newsboat";
        ExecStart = "${lib.getExe pkgs.flock} %t/newsboat.lock ${lib.getExe cfg.package} --vacuum";
      };
    };

    systemd.user.timers.newsboat-vacuum = lib.mkIf cfg.autoVacuum.enable {
      Unit = {
        Description = "Automatic Newsboat Cache Cleaner";
        Documentation = [ "man:newsboat(1)" ];
      };

      Timer = {
        Unit = "newsboat-vacuum.service";
        OnCalendar = cfg.autoVacuum.onCalendar;
        Persistent = true;
      };

      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
