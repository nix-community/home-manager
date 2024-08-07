{ config, lib, pkgs, ... }:

let

  cfg = config.programs.vesktop;
  jsonFormat = pkgs.formats.json { };

in {
  meta.maintainers = [ lib.hm.maintainers.LilleAila ];

  options.programs.vesktop = {
    enable = lib.mkEnableOption
      "Vesktop, an alternate client for Discord with Vencord built-in";
    package = lib.mkPackageOption pkgs "vesktop" { };
    settings = lib.mkOption {
      type = jsonFormat.type;
      default = { };
      description = ''
        Vesktop settings written to
        {file}`$XDG_CONFIG_HOME/vesktop/settings.json`. See
        <https://github.com/Vencord/Vesktop/blob/main/src/shared/settings.d.ts>
        for available options.
      '';
      example = lib.literalExpression ''
        {
          appBadge = false;
          arRPC = true;
          checkUpdates = false;
          customTitleBar = false;
          disableMinSize = true;
          minimizeToTray = false;
          tray = false;
          splashBackground = "#000000";
          splashColor = "#ffffff";
          splashTheming = true;
          staticTitle = true;
          hardwareAcceleration = true;
          discordBranch = "stable";
        }
      '';
    };

    vencord = {
      useSystem = lib.mkEnableOption "Vencord package from Nixpkgs";
      theme = lib.mkOption {
        description = "The theme to use for Vencord";
        default = null;
        type = with lib.types; nullOr (oneOf [ lines path ]);
      };
      settings = lib.mkOption {
        type = jsonFormat.type;
        default = { };
        description = ''
          Vencord settings written to
          {file}`$XDG_CONFIG_HOME/vesktop/settings/settings.json`. See
          <https://github.com/Vendicated/Vencord/blob/main/src/api/Settings.ts>
          for available options.
        '';
        example = lib.literalExpression ''
          {
            autoUpdate = false;
            autoUpdateNotification = false;
            notifyAboutUpdates = false;
            useQuickCss = true;
            disableMinSize = true;
            plugins = {
              MessageLogger = {
                enabled = true;
                ignoreSelf = true;
              };
              FakeNitro.enabled = true;
            };
          }
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = [
        (cfg.package.override { withSystemVencord = cfg.vencord.useSystem; })
      ];
      xdg.configFile."vesktop/settings.json".source =
        jsonFormat.generate "vesktop-settings" cfg.settings;
      xdg.configFile."vesktop/settings/settings.json".source =
        jsonFormat.generate "vencord-settings" cfg.vencord.settings;
    }
    (lib.mkIf (cfg.vencord.theme != null) {
      programs.vesktop.vencord.settings.enabledThemes = [ "theme.css" ];
      xdg.configFile."vesktop/themes/theme.css".source =
        if builtins.isPath cfg.vencord.theme
        || lib.isStorePath cfg.vencord.theme then
          cfg.vencord.theme
        else
          pkgs.writeText "vesktop/themes/theme.css" cfg.vencord.theme;
    })
  ]);
}
