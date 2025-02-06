{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkPackageOption mkIf mkOption types;

  cfg = config.programs.process-compose;

  settingsFormat = pkgs.formats.yaml { };
in {
  meta.maintainers = [ lib.hm.maintainers.dudeofawesome ];

  options.programs.process-compose = {
    enable = mkEnableOption "process-compose";

    package = mkPackageOption pkgs "process-compose" { };

    settings = mkOption {
      type = settingsFormat.type;
      default = null;
      description = ''
        Specify the configuration for process-compose.

        See https://f1bonacc1.github.io/process-compose/tui/#tui-state-settings for available options.
      '';
    };

    shortcuts = mkOption {
      type = settingsFormat.type;
      default = null;
      description = ''
        Specify shortcuts for process-compose.

        See https://f1bonacc1.github.io/process-compose/tui/#shortcuts-configuration for available options.
      '';
    };

    theme = mkOption {
      type = settingsFormat.type;
      default = null;
      description = ''
        Specify a theme for process-compose.

        See https://f1bonacc1.github.io/process-compose/tui/#tui-themes for available options.
      '';
    };
  };

  config = let
    configDir = if (pkgs.stdenv.targetPlatform.isDarwin) then
      "Library/Application Support/process-compose/"
    else
      "$XDG_CONFIG_HOME/process-compose/";
  in mkIf cfg.enable {
    home = {
      packages = [ cfg.package ];

      file.process-compose-settings = {
        enable = !builtins.isNull cfg.settings;
        target = "${configDir}/settings.yaml";
        source = settingsFormat.generate "settings.yaml" cfg.settings;
      };

      file.process-compose-shortcuts = {
        enable = !builtins.isNull cfg.shortcuts;
        target = "${configDir}/shortcuts.yaml";
        source = settingsFormat.generate "shortcuts.yaml" {
          shortcuts = cfg.shortcuts;
        };
      };

      file.process-compose-theme = {
        enable = !builtins.isNull cfg.theme;
        target = "${configDir}/theme.yaml";
        source = settingsFormat.generate "theme.yaml" cfg.theme;
      };
    };
  };
}
