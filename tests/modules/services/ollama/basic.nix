{
  config = {
    services.ollama.enable = true;

    test.stubs.ollama = { };

    nmt.script = ''
      serviceFile="home-files/.config/systemd/user/ollama.service"
      assertFileRegex "$serviceFile" 'After=network\.target'
      assertFileRegex "$serviceFile" 'Environment=OLLAMA_HOST=127.0.0.1:11434'
    '';
  };
}
