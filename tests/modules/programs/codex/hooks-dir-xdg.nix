{
  home.preferXdgDirectories = true;

  programs.codex = {
    enable = true;
    hooks = ./hooks-dir-xdg;
  };

  nmt.script = ''
    assertFileExists home-files/.config/codex/hooks.json
    assertFileContent home-files/.config/codex/hooks.json \
      ${./hooks-dir-xdg/hooks.json}

    assertFileExists home-files/.config/codex/hooks/session-start.sh
    assertFileContent home-files/.config/codex/hooks/session-start.sh \
      ${./hooks-dir-xdg/session-start.sh}

    assertPathNotExists home-files/.codex/hooks
  '';
}
