{
  programs.worktrunk = {
    enable = true;
    settings = {
      worktree-path = ".worktrees/{{ branch | sanitize }}";
      commit = {
        stage = "all";
        generation.command = "llm -m claude-haiku-4.5";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/worktrunk/config.toml
    assertFileContent home-files/.config/worktrunk/config.toml ${./expected.toml}
  '';
}
