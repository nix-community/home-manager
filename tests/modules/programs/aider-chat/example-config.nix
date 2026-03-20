{
  programs.aider-chat = {
    enable = true;
    settings = {
      verify-ssl = false;
      architect = true;
      auto-accept-architect = false;
      show-model-warnings = false;
      check-model-accepts-settings = false;
      cache-prompts = true;
      dark-mode = true;
      dirty-commits = false;
      lint = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.aider.conf.yml
    assertFileContent home-files/.aider.conf.yml \
      ${./aider.conf.yml}
  '';
}
