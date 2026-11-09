{
  programs.peon-ping = {
    enable = true;
    packs = [ ];
    settings = {
      active_pack = "glados";
      volume = 0.8;
      enabled = true;
      desktop_notifications = false;
      categories = {
        "session.start" = true;
        "task.complete" = true;
        "input.required" = false;
      };
    };
  };

  test.stubs.peon-ping = { };

  nmt.script = ''
    assertFileExists home-files/.claude/hooks/peon-ping/config.json
    assertFileContent home-files/.claude/hooks/peon-ping/config.json \
      ${./expected-config.json}
  '';
}
