{ ... }:
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
  };
  nmt.script = ''
    assertFileExists home-files/.config/aichat/config.yaml
    assertFileContent home-files/.config/aichat/config.yaml \
      ${./settings.yml}
  '';
}
