{ config, pkgs, ... }:

{
  config = {
    programs.opencommit = {
      enable = true;
      apiKey = "sk-nohook";
      language = "de";
      model = "claude-3";
      promptModule = "conventional-commit";
      setGitHook = false;
    };

    nmt.script = ''
      assertFileExists home-path/bin/oco
      assertFileContains home-path/activate \
        "export OCO_API_KEY=sk-nohook"
      assertFileContains home-path/activate \
        "export OCO_LANGUAGE=de"
      assertFileContains home-path/activate \
        "export OCO_MODEL=claude-3"
      assertFileContains home-path/activate \
        "export OCO_PROMPT_MODULE=conventional-commit"
      assertFileNotContains home-path/activate \
        "oco hook set"
    '';
  };
}
