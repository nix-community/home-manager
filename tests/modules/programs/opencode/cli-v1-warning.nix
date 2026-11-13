{
  imports = [ ./opencode-stubs.nix ];

  programs.opencode = {
    enable = true;
    cli.theme.name = "system";
    validateFiles.cli = true;
  };

  test.asserts.warnings.expected = [
    ''
      programs.opencode.cli requires OpenCode 2 or later, but the configured
      package is version 1.18.31.

      Use programs.opencode.tui for OpenCode 1, or update
      programs.opencode.package.
    ''
  ];

  test.asserts.assertions.expected = [
    "`programs.opencode.validateFiles.cli` requires `programs.opencode.package` to provide `passthru.jsonschema.cli` (OpenCode 2 or later)"
  ];
}
