{
  services.jankyborders.enable = true;
  xdg.configFile."borders/bordersrc".enable = false;
  home.file.borders-fallback = {
    target = ".bordersrc";
    source = toString ./jankyborders-config-expected;
    executable = true;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/borders/bordersrc
    assertFileContent home-files/.bordersrc ${./jankyborders-config-expected}
    assertFileIsExecutable home-files/.bordersrc
    assertFileContent \
      "$(normalizeStorePaths LaunchAgentRestartTriggers/org.nix-community.home.jankyborders.json)" \
      ${./expected-fallback-restart-triggers.json}
  '';
}
