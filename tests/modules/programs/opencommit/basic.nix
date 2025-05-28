{ config, pkgs, ... }:

{
  config = {
    programs.opencommit = {
      enable = true;
      apiKey = "sk-test";
      language = "fr";
      model = "gpt-4";
      promptModule = "@commitlint";
      setGitHook = true;
    };

    nmt.script = ''
      assertFileExists home-path/bin/oco
      assertFileContent home-path/activate \
        --substring "export OCO_API_KEY=sk-test"
      assertFileContent home-path/activate \
        --substring "export OCO_LANGUAGE=fr"
      assertFileContent home-path/activate \
        --substring "export OCO_MODEL=gpt-4"
      assertFileContent home-path/activate \
        --substring "export OCO_PROMPT_MODULE=@commitlint"
      assertFileContent home-path/activate \
        --substring "oco hook set"
    '';
  };
}
