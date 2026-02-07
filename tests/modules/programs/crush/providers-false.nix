{
  programs.crush = {
    enable = true;

    settings.providers = {
      test = {
        type = "openai-compat";
        base_url = "https://api.example.com";
        api_key = "$API_KEY";
        models = [
          {
            id = "test-model";
            name = "Test Model";
            # Explicitly set can_reason to false (should be retained)
            can_reason = false;
            # Explicitly set supports_attachments to false (should be retained)
            supports_attachments = false;
            context_window = 32000;
            default_max_tokens = 4096;
          }
        ];
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/crush/crush.json
    assertFileContent home-files/.config/crush/crush.json ${./expected-providers-false.json}
  '';
}
