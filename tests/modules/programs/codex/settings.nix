{
  programs.codex = {
    enable = true;
    settings = {
      model = "gemma3:latest";
      provider = "ollama";
      providers = {
        ollama = {
          name = "Ollama";
          baseURL = "http://localhost:11434/v1";
          envKey = "OLLAMA_API_KEY";
        };
      };
    };
  };
  nmt.script = ''
    assertFileExists home-files/.codex/config.yaml
    assertFileContent home-files/.codex/config.yaml \
      ${./settings.yml}
  '';
}
