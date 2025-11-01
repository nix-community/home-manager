{ ... }:

{
  services.local-ai = {
    enable = true;
    environment = {
      MODELS_PATH = "/tmp/models";
      PRELOAD_MODELS = "[{ \"url\": \"https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf\", \"name\": \"mistral-7b-instruct-v0.2.Q4_K_M.gguf\" }]";
    };
  };

  nmt.script = ''
    assertFileContains \
      home-files/.config/systemd/user/local-ai.service \
      "Environment=MODELS_PATH=/tmp/models"
    assertFileContains \
      home-files/.config/systemd/user/local-ai.service \
      "Environment=PRELOAD_MODELS=[{ \"url\": \"https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf\", \"name\": \"mistral-7b-instruct-v0.2.Q4_K_M.gguf\" }]"
  '';
}
