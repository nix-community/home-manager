{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    mkIf
    ;
  cfg = config.programs.eilmeldung;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [
    lib.maintainers.christo-auer
    lib.maintainers.rachitvrma
  ];

  options.programs.eilmeldung = {
    enable = mkEnableOption "eilmeldung, a TUI news feed reader";

    package = mkPackageOption pkgs "eilmeldung" { nullable = true; };

    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        mouse_support = true;

        feed_list = [
          "query: \"Marked\" marked"
          "query: \"Reviews\" #reviews"
          "feeds"
          "* categories"
          "tags"
        ];

        startup_commands = [ "sync" ];

        after_sync_commands = [
          "query lastsync"
          "tag rust title:\"rust\""
          "read title:/^Advertisement/"
          "refresh"
        ];

        video_enclosure_command = "mpv {url}";
        audio_enclosure_command = "mpv --no-audio {url}";

        share_targets = [
          "clipboard"
          "feh feh \"{url}\""
        ];

        input_config.mappings = {
          "; i" = [ "cmd hintshare feh" ];
          "y" = [
            "confirm in articles read all"
            "nextunread"
          ];
        };
      };

      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/eilmeldung/config.toml`.

        See
        <https://github.com/christo-auer/eilmeldung/blob/main/docs/configuration.md>
        for the full list of options.
      '';
    };
  };
  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."eilmeldung/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "eilmeldung-config.toml" cfg.settings;
    };
  };
}
