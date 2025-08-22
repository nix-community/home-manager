{
  programs.claude-code = {
    enable = true;
    memory = {
      text = ''
        # Project Memory

        ## Current Task
        Test implementation of memory management.

        ## Key Context
        - This is a test configuration
        - Memory should be created at ~/CLAUDE.md
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/CLAUDE.md
    assertFileContent home-files/CLAUDE.md ${./expected-memory.md}
  '';
}
