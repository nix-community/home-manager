{ config, pkgs, ... }:

{
  programs.crush = {
    enable = true;

    secretEnvVars = {
      ANTHROPIC_API_KEY = "/run/secrets/anthropic-key";
      OPENAI_API_KEY = "/run/secrets/openai-key";
      DEEPSEEK_API_KEY = "/run/secrets/deepseek-key";
    };
  };

  nmt.script = ''
    assertFileExists home-path/bin/crush
    assertFileRegex home-path/bin/crush "ANTHROPIC_API_KEY"
    assertFileRegex home-path/bin/crush "OPENAI_API_KEY"
    assertFileRegex home-path/bin/crush "DEEPSEEK_API_KEY"
    assertFileRegex home-path/bin/crush "/run/secrets/anthropic-key"
  '';
}
