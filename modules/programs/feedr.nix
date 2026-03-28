{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.feedr;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.maintainers; [ drupol ];

  options.programs.feedr = {
    enable = lib.mkEnableOption "A feature-rich terminal-based RSS/Atom feed reader written in Rust.";

    package = lib.mkPackageOption pkgs "feedr" { nullable = true; };

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          general = {
            max_dashboard_items = 100;
            auto_refresh_interval = 0;
            refresh_enabled = false;
            refresh_rate_limit_delay = 2000;
          };

          network = {
            http_timeout = 15;
            user_agent = "Mozilla/5.0 (compatible; Feedr/1.0; +https://github.com/bahdotsh/feedr)";
          };

          ui = {
            tick_rate = 100;
            error_display_timeout = 3000;
            theme = "dark";
            compact_mode = "auto";
          };

          default_feeds = [
            {
              url = "https://nixos.org/blog/stories-rss.xml";
              category = "NixOS";
            }
          ];
        };
      '';

      description = ''
        Settings for feedr.

        Configuration written to
        {file}`$XDG_CONFIG_HOME/feedr/config.toml`.

        Options are listed on the github: <https://github.com/bahdotsh/feedr>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [
      cfg.package
    ];

    xdg.configFile."feedr/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "feedr-config" cfg.settings;
    };
  };
}
