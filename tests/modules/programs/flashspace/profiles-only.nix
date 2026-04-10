{
  programs.flashspace = {
    enable = true;
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
              ];
            }
          ];
        }
      ];
    };
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/flashspace/settings.toml
    assertFileExists home-files/.config/flashspace/profiles.json
  '';
}
