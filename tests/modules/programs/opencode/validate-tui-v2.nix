{
  imports = [ ./opencode-v2-stubs.nix ];

  programs.opencode = {
    enable = true;
    validateFiles.tui = true;
  };

  test.asserts.assertions.expected = [
    "`programs.opencode.validateFiles.tui` requires `programs.opencode.package` to provide `passthru.jsonschema.tui` (OpenCode 1); OpenCode 2 moved TUI settings to `programs.opencode.cli`"
  ];
}
