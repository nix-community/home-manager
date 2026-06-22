{
  programs.flashspace = {
    enable = true;
    settings = {
      displayMode = "static";
      centerCursorOnWorkspaceChange = true;
      enableWorkspaceTransitions = true;
      workspaceTransitionDuration = 0.25;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/flashspace/settings.toml
    assertPathNotExists home-files/.config/flashspace/profiles.json
  '';
}
