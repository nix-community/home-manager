{
  config = {
    services.ollama = {
      enable = true;
      host = "localhost";
      port = 11111;
      environmentVariables = {
        OLLAMA_LLM_LIBRARY = "cpu";
        HIP_VISIBLE_DEVICES = "0,1";
      };
    };

    test.stubs.ollama = { };

    nmt.script = ''
      serviceFile="home-files/.config/systemd/user/ollama.service"
      assertFileRegex "$serviceFile" 'Environment=OLLAMA_HOST=localhost:11111'
      assertFileRegex "$serviceFile" 'Environment=OLLAMA_LLM_LIBRARY=cpu'
      assertFileRegex "$serviceFile" 'Environment=HIP_VISIBLE_DEVICES=0,1'
    '';
  };
}
