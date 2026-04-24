{
  programs.flashspace = {
    enable = true;
    settings = {
      displayMode = "static";
      centerCursorOnWorkspaceChange = true;
      enableWorkspaceTransitions = true;
      workspaceTransitionDuration = 0.25;
      integrations = {
        enableIntegrations = false;
      };
    };
    profiles = {
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
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/flashspace/settings.toml
    assertFileExists home-files/.config/flashspace/profiles.json
  '';
}
