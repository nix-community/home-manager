{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf mkOption;

  cfg = config.programs.herdr.core;

  tomlFormat = pkgs.formats.toml { };
  settingsSource = tomlFormat.generate "herdr-core-config.toml" cfg.settings;
in
{
  meta.maintainers = [ lib.maintainers.davsanchez ];

  options.programs.herdr.core = {
    enable = lib.mkEnableOption "herdr-core, the Herdr terminal daemon and hc CLI";

    package = lib.mkPackageOption pkgs "herdr-core" { nullable = true; };

    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = {
        shell = [
          "nu"
          "-l"
        ];
        draft_wait = 60;
        restore_screen = true;
      };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/herdr-core/config.toml`.

        herdr-core only reads this file (it never writes it), so unlike the
        desktop app's settings there is no mutable mode. Changes apply to the
        next new shell without restarting the core. See the core's README and
        `hc --help` for the available keys (`shell`, `detach_key`,
        `wait_timeout`, `notes`, `notes_quiet`, `draft_wait`, `headless`,
        `history_mb`, `restore_screen`, `socket`, `machine_timeout`).

        This is separate from {option}`programs.herdr.settings` (the TUI at
        {file}`$XDG_CONFIG_HOME/herdr/config.toml`) and
        {option}`programs.herdr.desktop.settings` (the app at
        {file}`$XDG_CONFIG_HOME/herdr-app/settings.json`).
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."herdr-core/config.toml" = mkIf (cfg.settings != { }) {
      source = settingsSource;
    };
  };
}
