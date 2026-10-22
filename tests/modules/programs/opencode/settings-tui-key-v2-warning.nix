{
  imports = [ ./opencode-v2-stubs.nix ];

  programs.opencode = {
    enable = true;
    settings.theme = "system";
  };

  test.asserts.warnings.expected = [
    ''
      programs.opencode.settings contains deprecated TUI-specific keys: theme

      These settings should be moved to programs.opencode.cli instead.

      OpenCode requires terminal client settings in cli.json.
      See: https://opencode.ai/v2/docs/cli/config
    ''
  ];
}
