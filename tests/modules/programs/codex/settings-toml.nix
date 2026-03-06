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
          baseURL = "http://localhost:11434/v1";
          envKey = "OLLAMA_API_KEY";
        };
      };
    };
    custom-instructions = ''
      - Always respond with emojis
      - Only use git commands when explicitly requested
    '';
  };
  nmt.script = ''
    assertFileExists home-files/.codex/config.toml
    assertFileContent home-files/.codex/config.toml \
      ${./config.toml}
    assertFileExists home-files/.codex/AGENTS.md
    assertFileContent home-files/.codex/AGENTS.md \
      ${./AGENTS.md}
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'CODEX_HOME'
  '';
}
