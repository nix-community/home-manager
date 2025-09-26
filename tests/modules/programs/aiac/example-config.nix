{
  programs.aiac = {
    enable = true;
    settings = {
      default_backend = "official_openai";
      backends = {
        official_openai = {
          type = "openai";
          api_key = "API KEY";
          default_model = "gpt-4o";
        };

        localhost = {
          type = "ollama";
          url = "http://localhost:11434/api";
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/aiac/aiac.toml
    assertFileContent home-files/.config/aiac/aiac.toml \
      ${./aiac.toml}
  '';
}
