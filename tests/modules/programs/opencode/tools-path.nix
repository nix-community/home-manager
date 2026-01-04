{
  programs.opencode = {
    enable = true;
    tools = {
      test-tool = ./test-tool.ts;
    };
  };
  nmt.script = ''
    assertFileExists home-files/.config/opencode/tool/test-tool.ts
    assertFileContent home-files/.config/opencode/tool/test-tool.ts \
      ${./test-tool.ts}
  '';
}
