{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.newsboat;
  wrapQuote = x: "\"${x}\"";

in

{
  options = {
    programs.newsboat = {
      enable = mkEnableOption "the Newsboat feed reader";

      urls = mkOption {
        type = types.listOf types.attrs;
        default = [];
        example = [{url = "http://example.com"; tags = ["foo" "bar"];}];
        description = "List of urls and tokens.";
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
        description = "Whether to enable automatic reloading while newsboat is running.";
      };

      reloadTime = mkOption {
        type = types.nullOr types.int;
        default = 60;
        description = "Time in minutes between reloads.";
      };

      browser = mkOption {
        type = types.str;
        default = "${pkgs.xdg_utils}/bin/xdg-open";
        description = "External browser to use.";
      };

      queries = mkOption {
        type = types.attrsOf types.str;
        default = {};
        example = {
          "foo" = "rssurl =~ \"example.com\"";
        };
        description = "A list of queries to use.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra configuration values that will be appended to the end.";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.newsboat ];
    home.file.".newsboat/urls".text =
      let
        urls = builtins.concatStringsSep "\n" (
          map (u: builtins.concatStringsSep " " ([u.url] ++ (map wrapQuote u.tags)))
            cfg.urls);
        queries = builtins.concatStringsSep "\n" (
          mapAttrsToList (n: v: "\"query:${n}:${escape ["\""] v}\"") cfg.queries);

      in

      ''
        ${urls}

        ${queries}
      '';
    home.file.".newsboat/config".text = ''
      max-items ${toString cfg.maxItems}
      browser ${cfg.browser}
      reload-threads ${toString cfg.reloadThreads}
      auto-reload ${if cfg.autoReload then "yes" else "no"}
      ${optionalString (cfg.reloadTime != null) (toString "reload-time ${toString cfg.reloadTime}")}
      prepopulate-query-feeds yes

      ${cfg.extraConfig}
    '';
  };
}
