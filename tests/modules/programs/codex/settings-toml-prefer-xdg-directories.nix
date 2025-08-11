{ pkgs, ... }:
let
  codexPackage = pkgs.runCommand "codex-0.2.0" { } ''
    mkdir -p $out/bin
    echo '#!/bin/sh' > $out/bin/codex
    chmod +x $out/bin/codex
  '';
in
{
  home.preferXdgDirectories = true;
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
  };
  nmt.script = ''
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export CODEX_HOME="/home/hm-user/.config/codex"'
    assertFileExists home-files/.config/codex/config.toml
    assertFileContent home-files/.config/codex/config.toml \
      ${./config.toml}
  '';
}
