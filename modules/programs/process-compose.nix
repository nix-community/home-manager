{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [ lib.hm.maintainers.stijnruts ];

  options.programs.process-compose = {
    enable = lib.mkEnableOption "Process Compose, a simple and flexible scheduler and orchestrator to manage non-containerized applications";

    package = lib.mkPackageOption pkgs "process-compose" { nullable = true; };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      example = {
        theme = "Cobalt";
        sort = {
          by = "NAME";
          isReversed = false;
        };
        disable_exit_confirmation = false;
      };
      description = ''
        Written to {file}`$XDG_CONFIG_HOME/process-compose/settings.yaml`

        See <https://f1bonacc1.github.io/process-compose/tui/#tui-state-settings>
      '';
    };

    theme = mkOption {
      type = yamlFormat.type;
      default = { };
      example = {
        body = {
          fgColor = "white";
          bgColor = "black";
          secondaryTextColor = "yellow";
          tertiaryTextColor = "green";
          borderColor = "white";
        };
        stat_table = {
          keyFgColor = "yellow";
          valueFgColor = "white";
          logoColor = "yellow";
        };
        proc_table = {
          fgColor = "lightskyblue";
          fgWarning = "yellow";
          fgPending = "grey";
          fgCompleted = "lightgreen";
          fgError = "red";
          headerFgColor = "white";
        };
        help = {
          fgColor = "black";
          keyColor = "white";
          hlColor = "green";
          categoryFgColor = "lightskyblue";
        };
        dialog = {
          fgColor = "cadetblue";
          bgColor = "black";
          buttonFgColor = "black";
          buttonBgColor = "lightskyblue";
          buttonFocusFgColor = "black";
          buttonFocusBgColor = "dodgerblue";
          labelFgColor = "yellow";
          fieldFgColor = "black";
          fieldBgColor = "lightskyblue";
        };
      };
      description = ''
        Written to {file}`$XDG_CONFIG_HOME/process-compose/theme.yaml`

        See <https://f1bonacc1.github.io/process-compose/tui/#tui-themes>
      '';
    };

    shortcuts = mkOption {
      type = yamlFormat.type;
      default = { };
      example = {
        log_follow = {
          toggle_description = {
            false = "Follow Off";
            true = "Follow On";
          };
          shortcut = "F5";
        };
        log_screen = {
          toggle_description = {
            false = "Half Screen";
            true = "Full Screen";
          };
          shortcut = "F4";
        };
        log_wrap = {
          toggle_description = {
            false = "Wrap Off";
            true = "Wrap On";
          };
          shortcut = "F6";
        };
        process_restart = {
          description = "Restart";
          shortcut = "Ctrl-R";
        };
        process_screen = {
          toggle_description = {
            false = "Half Screen";
            true = "Full Screen";
          };
          shortcut = "F8";
        };
        process_start = {
          description = "Start";
          shortcut = "F7";
        };
        process_stop = {
          description = "Stop";
          shortcut = "F9";
        };
        quit = {
          description = "Quit";
          shortcut = "F10";
        };
      };
      description = ''
        Written to {file}`$XDG_CONFIG_HOME/process-compose/shortcuts.yaml`

        See <https://f1bonacc1.github.io/process-compose/tui/#shortcuts-configuration>
      '';
    };
  };

  config =
    let
      cfg = config.programs.process-compose;
    in
    lib.mkIf cfg.enable {
      home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      xdg.configFile = {
        "process-compose/settings.yaml" = lib.mkIf (cfg.settings != { }) {
          source = yamlFormat.generate "process-compose-settings" cfg.settings;
        };
        "process-compose/theme.yaml" = lib.mkIf (cfg.theme != { }) {
          source = yamlFormat.generate "process-compose-theme" { style = cfg.theme; };
        };
        "process-compose/shortcuts.yaml" = lib.mkIf (cfg.shortcuts != { }) {
          source = yamlFormat.generate "process-compose-shortcuts" { shortcuts = cfg.shortcuts; };
        };
      };
    };
}
