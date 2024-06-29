{ config, pkgs, ... }:

{
  config = {
    programs.vesktop = {
      enable = true;
      settings = {
        tray = false;
        minimizeToTray = false;
        hardwareAcceleration = true;
        customTitleBar = false;
        staticTitle = true;
        discordBranch = "stable";
      };
      vencord = {
        theme = ''
          .privateChannels_f0963d::after {
            content: "";
            position: absolute;
            width: 100%;
            height: 100%;
            top: 0;
            left: 0;
            z-index: 1000;
            background: linear-gradient(to bottom, transparent 85%, var(--base00));
            pointer-events: none;
          }
        '';
        settings = {
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
        };
      };
    };

    nmt.script = ''
      configDir=home-files/.config/vesktop
      assertFileExists $configDir/settings.json
      assertFileContent $configDir/settings.json \
        ${./basic-settings.json}
      assertFileExists $configDir/settings/settings.json
      assertFileContent $configDir/settings/settings.json \
        ${./basic-vencord-settings.json}
      assertFileExists $configDir/themes/theme.css
      assertFileContent $configDir/themes/theme.css \
        ${./basic-theme.css}
    '';
  };
}
