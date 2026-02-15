{
  programs.crush = {
    enable = true;

    settings.providers = {
      # Minimal provider with only api_key
      openrouter = {
        api_key = "$OPENROUTER_API_KEY";
      };
      # Provider with some fields but no models
      custom = {
        type = "openai-compat";
        base_url = "https://api.example.com/v1";
        api_key = "$CUSTOM_API_KEY";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/crush/crush.json
    assertFileContent home-files/.config/crush/crush.json ${./expected-providers-minimal.json}
  '';
}
