{
  programs.aichat = {
    enable = true;
    settings = {
      model = "ollama:llama3.2:latest";
      clients = [
        {
          type = "openai-compatible";
          name = "ollama";
          api_base = "http://localhost:11434/v1";
          models = [
            {
              name = "llama3.2:latest";
              supports_function_calling = true;
            }
          ];
        }
      ];
    };

    agents = {
      openai = {
        model = "openai:gpt-4o";
        temperature = 0.5;
        top_p = 0.7;
        use_tools = "fs,web_search";
        agent_prelude = "default";
      };

      llama = {
        model = "llama3.2:latest";
        temperature = 0.5;
        use_tools = "web_search";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/aichat/config.yaml
    assertFileContent home-files/.config/aichat/config.yaml \
      ${./settings.yml}

    assertFileExists home-files/.config/aichat/agents/openai/config.yaml
    assertFileExists home-files/.config/aichat/agents/llama/config.yaml
    assertFileContent home-files/.config/aichat/agents/openai/config.yaml \
      ${./openai.yaml}
    assertFileContent home-files/.config/aichat/agents/llama/config.yaml \
      ${./llama.yaml}
  '';
}
