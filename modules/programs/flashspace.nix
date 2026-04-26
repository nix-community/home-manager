{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.flashspace;
  tomlFormat = pkgs.formats.toml { };
  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = with lib.maintainers; [ philocalyst ];

  options.programs.flashspace = {
    enable = lib.mkEnableOption "FlashSpace workspace manager for macOS";

    package = lib.mkPackageOption pkgs "flashspace" { nullable = true; };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          showFlashSpace = "cmd+shift+space";
          toggleFlashSpace = "control+option+command+t";
          showFloatingNotifications = true;
          displayMode = "static";
          centerCursorOnWorkspaceChange = true;
          enableWorkspaceTransitions = true;
          workspaceTransitionDuration = 0.25;
          integrations = {
            enableIntegrations = true;
            runScriptOnWorkspaceChange = "~/.config/flashspace/scripts/notify.sh";
          };
        }
      '';
      description = ''
        General app settings written to
        {file}`$XDG_CONFIG_HOME/flashspace/settings.toml`.

        Covers hotkeys, display mode, transition effects, focus navigation,
        gestures, integrations, and advanced options.

        See <https://github.com/wojciech-zurek/FlashSpace> for available keys.
      '';
    };

    profiles = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          profiles = [
            {
              id = "550e8400-e29b-41d4-a716-446655440000";
              name = "Work";
              shortcut = "control+option+1";
              workspaces = [
                {
                  id = "a1b2c3d4-e5f6-7890-abcd-ef1234567890";
                  name = "Coding";
                  display = "Built-in Retina Display";
                  shortcut = "cmd+1";
                  symbolIconName = "terminal.fill";
                  openAppsOnActivation = true;
                  apps = [
                    {
                      name = "Xcode";
                      bundleIdentifier = "com.apple.dt.Xcode";
                      autoOpen = true;
                    }
                    {
                      name = "iTerm2";
                      bundleIdentifier = "com.googlecode.iterm2";
                      autoOpen = true;
                    }
                  ];
                }
                {
                  id = "b2c3d4e5-f6a7-8901-bcde-f12345678901";
                  name = "Communication";
                  display = "Built-in Retina Display";
                  shortcut = "cmd+2";
                  symbolIconName = "message.fill";
                  openAppsOnActivation = false;
                  apps = [
                    {
                      name = "Slack";
                      bundleIdentifier = "com.tinyspeck.slackmacgap";
                      autoOpen = false;
                    }
                  ];
                }
              ];
            }
          ];
        }
      '';
      description = ''
        Profiles, workspaces, and app assignments written to
        {file}`$XDG_CONFIG_HOME/flashspace/profiles.json`.

        The root attribute must be {var}`profiles`, containing a list of profile
        objects. Each profile holds a list of {var}`workspaces`, and each
        workspace holds a list of {var}`apps` identified by their
        {var}`bundleIdentifier`.

        See <https://github.com/wojciech-zurek/FlashSpace> for the full schema.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.flashspace" pkgs lib.platforms.darwin)
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = {
      "flashspace/settings.toml" = lib.mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "flashspace-settings" cfg.settings;
      };

      "flashspace/profiles.json" = lib.mkIf (cfg.profiles != { }) {
        source = jsonFormat.generate "flashspace-profiles" cfg.profiles;
      };
    };
  };
}
