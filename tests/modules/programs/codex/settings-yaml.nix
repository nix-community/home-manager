{ pkgs, ... }:
let
  codexPackage = pkgs.runCommand "codex-0.1.2504301751" { } ''
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
      provider = "ollama";
      providers = {
        ollama = {
          name = "Ollama";
          baseURL = "http://localhost:11434/v1";
          envKey = "OLLAMA_API_KEY";
        };
      };
    };
  };
  nmt.script = ''
    assertFileExists home-files/.codex/config.yaml
    assertFileContent home-files/.codex/config.yaml \
      ${./config.yaml}
  '';
}
