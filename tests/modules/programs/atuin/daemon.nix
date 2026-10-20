{
  programs.atuin = {
    enable = true;
    daemon.enable = true;
    themes.unrelated.theme.name = "Unrelated";
  };

  nmt.script = ''
    assertFileContent \
      "$(normalizeStorePaths LaunchAgentRestartTriggers/org.nix-community.home.atuin-daemon.json)" \
      ${./expected-restart-triggers.json}
  '';
}
