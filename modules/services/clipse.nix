{ pkgs, config, lib, ... }:
let
  cfg = config.services.clipse;
  jsonFormat = pkgs.formats.json { };
in {
  meta.maintainers = [ lib.hm.maintainers.dsoverlord ];

  options.services.clipse = {
    enable = lib.mkEnableOption "Enable clipse clipboard manager";

    package = lib.mkPackageOption pkgs "clipse" { };

    systemdTarget = lib.mkOption {
      type = lib.types.str;
      default = "graphical-session.target";
      example = "sway-session.target";
      description = ''
        The systemd target that will automatically start the clipse service.

        When setting this value to `"sway-session.target"`,
        make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
        otherwise the service may never be started.
      '';
    };

    allowDuplicates = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow duplicates";
    };

    historySize = lib.mkOption {
      type = lib.types.int;
      default = 100;
      description = "Number of history lines to keep.";
    };

    theme = lib.mkOption {
      type = jsonFormat.type;

      default = { useCustomTheme = false; };

      example = lib.literalExpression ''
        {
          useCustomTheme = true;
          DimmedDesc = "#ffffff";
          DimmedTitle = "#ffffff";
          FilteredMatch = "#ffffff";
          NormalDesc = "#ffffff";
          NormalTitle = "#ffffff";
          SelectedDesc = "#ffffff";
          SelectedTitle = "#ffffff";
          SelectedBorder = "#ffffff";
          SelectedDescBorder = "#ffffff";
          TitleFore = "#ffffff";
          Titleback = "#434C5E";
          StatusMsg = "#ffffff";
          PinIndicatorColor = "#ff0000";
        };
      '';

      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/clipse/custom_theme.json`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.clipse" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."clipse/config.json".source =
      jsonFormat.generate "settings" {
        allowDuplicates = cfg.allowDuplicates;
        historyFile = "clipboard_history.json";
        maxHistory = cfg.historySize;
        logFile = "clipse.log";
        themeFile = "custom_theme.json";
        tempDir = "tmp_files";
      };

    xdg.configFile."clipse/custom_theme.json".source =
      jsonFormat.generate "theme" cfg.theme;

    systemd.user.services.clipse = lib.mkIf pkgs.stdenv.isLinux {
      Unit = {
        Description = "Clipse listener";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${cfg.package}/bin/clipse -listen";
      };

      Install = { WantedBy = [ cfg.systemdTarget ]; };
    };
  };
}
