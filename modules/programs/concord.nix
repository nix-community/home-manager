{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.concord;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.maintainers; [ yarn ];

  options.programs.concord = {
    enable = lib.mkEnableOption "Feature-rich TUI client for Discord";

    package = lib.mkPackageOption pkgs "concord-tui" { nullable = true; };

    settings = lib.mkOption {
      type = lib.types.submodule { freeformType = tomlFormat.type; };
      default = { };
      description = ''
        Concord configuration.
        See <https://github.com/chojs23/concord/blob/main/src/config/options.rs> for supported values.
      '';
    };

    keymapSettings = lib.mkOption {
      type = lib.types.submodule { freeformType = tomlFormat.type; };
      default = { };
      description = ''
        Concord keymap configuration.
        See <https://github.com/chojs23/concord/blob/main/docs/keymap-options.md> for supported values.
      '';
    };

    themeSettings = lib.mkOption {
      type = lib.types.submodule { freeformType = tomlFormat.type; };
      default = { };
      description = ''
        Concord theme configuration.
        See <https://github.com/chojs23/concord/blob/main/docs/theme-options.md> for supported values.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."concord/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "concord-config.toml" cfg.settings;
    };

    xdg.configFile."concord/keymap.toml" = lib.mkIf (cfg.keymapSettings != { }) {
      source = tomlFormat.generate "concord-keymap.toml" { keymap = cfg.keymapSettings; };
    };

    xdg.configFile."concord/theme.toml" = lib.mkIf (cfg.themeSettings != { }) {
      source = tomlFormat.generate "concord-theme.toml" cfg.themeSettings;
    };
  };
}
