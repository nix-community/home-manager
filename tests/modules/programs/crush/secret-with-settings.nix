{ config, pkgs, ... }:

{
  programs.crush = {
    enable = true;

    secretEnvVars = {
      ANTHROPIC_API_KEY = "/run/secrets/anthropic-key";
      OPENAI_API_KEY = "/run/secrets/openai-key";
    };

    settings = {
      options = {
        disabled_tools = [ "sourcegraph" ];
        initialize_as = "AGENTS.md";
      };
      lsp = {
        go.command = "gopls";
        rust.command = "rust-analyzer";
      };
      providers = {
        anthropic = {
          api_key = "$ANTHROPIC_API_KEY";
        };
        openai = {
          api_key = "$OPENAI_API_KEY";
          base_url = "https://api.openai.com/v1";
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-path/bin/crush
    assertFileRegex home-path/bin/crush "ANTHROPIC_API_KEY"
    assertFileRegex home-path/bin/crush "OPENAI_API_KEY"
    assertFileRegex home-path/bin/crush "/run/secrets/anthropic-key"
    assertFileRegex home-path/bin/crush "/run/secrets/openai-key"

    assertFileExists home-files/.config/crush/crush.json
    assertFileContent home-files/.config/crush/crush.json ${./expected-secret-with-settings.json}
  '';
}
