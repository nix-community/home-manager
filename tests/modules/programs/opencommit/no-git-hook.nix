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
      assertFileContent home-path/activate \
        --substring "export OCO_API_KEY=sk-nohook"
      assertFileContent home-path/activate \
        --substring "export OCO_LANGUAGE=de"
      assertFileContent home-path/activate \
        --substring "export OCO_MODEL=claude-3"
      assertFileContent home-path/activate \
        --substring "export OCO_PROMPT_MODULE=conventional-commit"
      assertFileNotContent home-path/activate \
        --substring "oco hook set"
    '';
  };
}
