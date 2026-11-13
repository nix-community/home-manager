{
  imports = [ ./opencode-v2-stubs.nix ];

  programs.opencode = {
    enable = true;
    tui.theme = "system";
  };

  test.asserts.warnings.expected = [
    ''
      programs.opencode.tui is ignored by OpenCode 2.

      OpenCode 2 replaced tui.json with a single global cli.json. Move
      terminal client settings to programs.opencode.cli. When
      programs.opencode.mutableSettings is enabled, OPENCODE_TUI_CONFIG is
      ignored as well.

      OpenCode 2 only migrates an existing tui.json when cli.json does not
      exist. See: https://opencode.ai/v2/docs/cli/config
    ''
  ];
}
