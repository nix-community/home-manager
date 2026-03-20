{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.twitch-tui;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.twitch-tui = {
    enable = mkEnableOption "twitch-tui";
    package = mkPackageOption pkgs "twitch-tui" { nullable = true; };
    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = {
        twitch = {
          username = "";
          channel = "";
          server = "wss://eventsub.wss.twitch.tv/ws";
          token = "";
        };

        terminal = {
          delay = 30;
          maximum_messages = 500;
          log_file = "";
          log_level = "info";
          first_state = "dashboard";
        };
      };
      description = ''
        Configuration settings for twitch-tui. All the available options
        can be found here: <https://github.com/Xithrius/twitch-tui/blob/main/default-config.toml>
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."twt/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "twitch-tui-config" cfg.settings;
    };
  };
}
