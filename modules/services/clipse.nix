{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.services.clipse;
  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = [ lib.hm.maintainers.dsoverlord ];

  imports = [
    (lib.mkRenamedOptionModule
      [ "services" "clipse" "allowDuplicates" ]
      [ "services" "clipse" "settings" "allowDuplicates" ]
    )
    (lib.mkRenamedOptionModule
      [ "services" "clipse" "imageDisplay" ]
      [ "services" "clipse" "settings" "imageDisplay" ]
    )
    (lib.mkRenamedOptionModule
      [ "services" "clipse" "keyBindings" ]
      [ "services" "clipse" "settings" "keyBindings" ]
    )
    (lib.mkRenamedOptionModule
      [ "services" "clipse" "historySize" ]
      [ "services" "clipse" "settings" "maxHistory" ]
    )
  ];

  options.services.clipse = {
    enable = lib.mkEnableOption "Enable clipse clipboard manager";

    package = lib.mkPackageOption pkgs "clipse" { nullable = true; };

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

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          allowDuplicates = true;
          maxHistory = 1001;
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/clipse/config.json`

        Please refer to <https://github.com/savedra1/clipse#configuration> for
        more information.
      '';
    };

    theme = lib.mkOption {
      type = lib.types.either jsonFormat.type lib.types.path;

      default = {
        useCustomTheme = false;
      };

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
      (lib.hm.assertions.assertPlatform "services.clipse" pkgs lib.platforms.linux)
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = {
      "clipse/config.json".source = jsonFormat.generate "settings" cfg.settings;
      "clipse/custom_theme.json".source =
        if lib.hm.strings.isPathLike cfg.theme then cfg.theme else jsonFormat.generate "theme" cfg.theme;
    };

    systemd.user.services.clipse = lib.mkIf (cfg.package != null) {
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

      Install = {
        WantedBy = [ cfg.systemdTarget ];
      };
    };
  };
}
