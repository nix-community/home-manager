{
  programs.codex = {
    enable = true;
    hooks = ./hooks-dir;
  };

  nmt.script = ''
    assertFileExists home-files/.codex/hooks.json
    assertFileContent home-files/.codex/hooks.json \
      ${./hooks-dir/hooks.json}

    assertFileExists home-files/.codex/hooks/session-start.sh
    assertFileContent home-files/.codex/hooks/session-start.sh \
      ${./hooks-dir/session-start.sh}
  '';
}
