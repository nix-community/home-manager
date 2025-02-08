{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.newsboat;
  wrapQuote = x: ''"${x}"'';

  urlsFileContents = let
    mkUrlEntry = u:
      concatStringsSep " " ([ u.url ] ++ map wrapQuote u.tags
        ++ optional (u.title != null) (wrapQuote "~${u.title}"));
    urls = map mkUrlEntry cfg.urls;

    mkQueryEntry = n: v: ''"query:${n}:${escape [ ''"'' ] v}"'';
    queries = mapAttrsToList mkQueryEntry cfg.queries;
  in concatStringsSep "\n"
  (if versionAtLeast config.home.stateVersion "20.03" then
    queries ++ urls
  else
    urls ++ queries) + "\n";

  configFileContents = ''
    max-items ${toString cfg.maxItems}
    browser ${cfg.browser}
    reload-threads ${toString cfg.reloadThreads}
    auto-reload ${lib.hm.booleans.yesNo cfg.autoReload}
    ${optionalString (cfg.reloadTime != null)
    (toString "reload-time ${toString cfg.reloadTime}")}
    prepopulate-query-feeds yes

    ${cfg.extraConfig}
  '';

in {
  meta.maintainers = [ maintainers.sumnerevans ];

  options = {
    programs.newsboat = {
      enable = mkEnableOption "the Newsboat feed reader";

      package = mkPackageOption pkgs "newsboat" { };

      urls = mkOption {
        type = types.listOf (types.submodule {
          options = {
            url = mkOption {
              type = types.str;
              example = "http://example.com";
              description = "Feed URL.";
            };

            tags = mkOption {
              type = types.listOf types.str;
              default = [ ];
              example = [ "foo" "bar" ];
              description = "Feed tags.";
            };

            title = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "ORF News";
              description = "Feed title.";
            };
          };
        });
        default = [ ];
        example = [{
          url = "http://example.com";
          tags = [ "foo" "bar" ];
        }];
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
        description = "External browser to use.";
      };

      queries = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = { "foo" = ''rssurl =~ "example.com"''; };
        description = "A list of queries to use.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra configuration values that will be appended to the end.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = cfg.queries != { } -> cfg.urls != [ ];
      message = ''
        Cannot specify queries if urls is empty. Unset queries if you
        want to manage urls imperatively.
      '';
    }];

    home.packages = [ cfg.package ];

    # Use ~/.newsboat on stateVersion < 21.05 and use ~/.config/newsboat for
    # stateVersion >= 21.05.
    home.file = mkIf (versionOlder config.home.stateVersion "21.05") {
      ".newsboat/urls" = mkIf (cfg.urls != [ ]) { text = urlsFileContents; };
      ".newsboat/config".text = configFileContents;
    };
    xdg.configFile = mkIf (versionAtLeast config.home.stateVersion "21.05") {
      "newsboat/urls" = mkIf (cfg.urls != [ ]) { text = urlsFileContents; };
      "newsboat/config".text = configFileContents;
    };
  };
}
