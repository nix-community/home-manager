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
      assertFileContains home-path/activate \
        "export OCO_API_KEY=sk-test"
      assertFileContains home-path/activate \
        "export OCO_LANGUAGE=fr"
      assertFileContains home-path/activate \
        "export OCO_MODEL=gpt-4"
      assertFileContains home-path/activate \
        "export OCO_PROMPT_MODULE=@commitlint"
      assertFileContains home-path/activate \
        "oco hook set"
    '';
  };
}
