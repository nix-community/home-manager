{
  programs.crush = {
    enable = true;

    settings.providers = {
      deepseek = {
        type = "openai-compat";
        base_url = "https://api.deepseek.com/v1";
        api_key = "$DEEPSEEK_API_KEY";
        models = [
          {
            id = "deepseek-chat";
            name = "Deepseek V3";
            cost_per_1m_in = 0.27;
            cost_per_1m_out = 1.1;
            cost_per_1m_in_cached = 0.07;
            cost_per_1m_out_cached = 1.1;
            context_window = 64000;
            default_max_tokens = 5000;
          }
        ];
      };
      custom-anthropic = {
        type = "anthropic";
        base_url = "https://api.anthropic.com/v1";
        api_key = "$ANTHROPIC_API_KEY";
        extra_headers = {
          "anthropic-version" = "2023-06-01";
        };
        models = [
          {
            id = "claude-sonnet-4-20250514";
            name = "Claude Sonnet 4";
            cost_per_1m_in = 3.0;
            cost_per_1m_out = 15.0;
            context_window = 200000;
            default_max_tokens = 50000;
            can_reason = true;
            supports_attachments = true;
          }
        ];
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/crush/crush.json
    assertFileContent home-files/.config/crush/crush.json ${./expected-providers-config.json}
  '';
}
