{
  programs.pi-coding-agent = {
    enable = true;
    models = {
      providers = {
        litellm = {
          baseUrl = "http://localhost:11434/v1";
          api = "openai-completions";
          apiKey = "ollama";
          models = [ { id = "llama3.1:8b"; } ];
        };
      };
    };
  };
  nmt.script = ''
    assertFileExists home-files/.pi/agent/models.json
    assertFileContent home-files/.pi/agent/models.json \
      ${./models.json}
  '';
}
