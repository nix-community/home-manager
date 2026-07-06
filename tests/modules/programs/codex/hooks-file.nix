{
  programs.codex = {
    enable = true;
    hooks = ./hooks.json;
  };

  nmt.script = ''
    assertFileExists home-files/.codex/hooks.json
    assertFileContent home-files/.codex/hooks.json \
      ${./hooks.json}
  '';
}
