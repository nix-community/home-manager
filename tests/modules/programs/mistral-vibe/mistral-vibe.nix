{
  programs.mistral-vibe = {
    enable = true;

    settings = {
      active_model = "tracer-vibe";

      providers = [
        {
          name = "tracer-proxy";
          api_base = "http://tracer:8081/proxy";
          api_key_env_var = "OPENROUTER_API_KEY";
          api_style = "openai";
          backend = "generic";
        }
      ];
      models = [
        {
          name = "mistralai/devstral-2512:free";
          provider = "tracer-proxy";
          alias = "tracer-vibe";
          temperature = 0.1;
          input_price = 0.0;
          output_price = 0.0;
        }
      ];
    };
  };

  nmt.script = ''
    assertFileExists home-files/.vibe/config.toml
    assertFileContent home-files/.vibe/config.toml ${./expected.toml}
  '';
}
