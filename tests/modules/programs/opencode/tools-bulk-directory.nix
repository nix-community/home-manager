{
  programs.opencode = {
    enable = true;
    tools = ./tools-bulk;
  };

  nmt.script = ''
    assertFileExists home-files/.config/opencode/tools/database-query.ts
    assertFileExists home-files/.config/opencode/tools/api-client.ts
    assertFileContent home-files/.config/opencode/tools/database-query.ts \
      ${./tools-bulk/database-query.ts}
    assertFileContent home-files/.config/opencode/tools/api-client.ts \
      ${./tools-bulk/api-client.ts}
  '';
}
