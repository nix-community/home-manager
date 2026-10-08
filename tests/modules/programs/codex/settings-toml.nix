{ pkgs, ... }:
let
  codexPackage = pkgs.runCommand "codex-0.2.0" { } ''
    mkdir -p $out/bin
    echo '#!/bin/sh' > $out/bin/codex
    chmod +x $out/bin/codex
  '';
in
{
  programs.codex = {
    enable = true;
    package = codexPackage;
    settings = {
      model = "gemma3:latest";
      model_provider = "ollama";
      model_providers = {
        ollama = {
          name = "Ollama";
          base_url = "http://localhost:11434/v1";
          env_key = "OLLAMA_API_KEY";
        };
      };
    };
    context = ''
      - Always respond with emojis
      - Only use git commands when explicitly requested
    '';
    contextOverride = ''
      - Temporarily prefer terse answers
      - Use exact dates in status notes
    '';
    hooks = {
      PreToolUse = [
        {
          matcher = "^Bash$";
          hooks = [
            {
              type = "command";
              command = "/usr/local/bin/codex-pre-tool-use";
              timeout = 30;
              statusMessage = "Checking Bash command";
            }
          ];
        }
      ];
      Stop = [
        {
          hooks = [
            {
              type = "command";
              command = "/usr/local/bin/codex-stop";
            }
          ];
        }
      ];
    };
  };
  nmt.script = ''
    assertFileExists home-files/.codex/config.toml
    assertFileContent home-files/.codex/config.toml \
      ${./config.toml}
    assertFileExists home-files/.codex/AGENTS.md
    assertFileContent home-files/.codex/AGENTS.md \
      ${./AGENTS.md}
    assertFileExists home-files/.codex/AGENTS.override.md
    assertFileContent home-files/.codex/AGENTS.override.md \
      ${builtins.toFile "expected-codex-context-override.md" ''
        - Temporarily prefer terse answers
        - Use exact dates in status notes
      ''}
    assertFileExists home-files/.codex/hooks.json
    assertFileContent home-files/.codex/hooks.json \
      ${./hooks.json}
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'CODEX_HOME'
  '';
}
