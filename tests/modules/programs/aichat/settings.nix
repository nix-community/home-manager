{ ... }:
{
  programs.aichat = {
    enable = true;
    settings = {
      model = "Ollama:mistral-small:latest";
      clients = [
        {
          type = "openai-compatible";
          name = "Ollama";
          api_base = "http://localhost:11434/v1";
          models = [
            {
              name = "llama3.2:latest";
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
