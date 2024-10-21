{
  config = {
    services.ollama = {
      enable = true;
      loadModels = [ "llama2" ];
    };

    test.stubs.ollama = { };

    nmt.script = ''
      serviceFile="home-files/.config/systemd/user/ollama.service"
      assertFileRegex "$serviceFile" 'ExecStartPost=/nix/store/.*-ollama-post-start'
      generated="$(grep -o '/nix/store/.*-ollama-post-start' "$TESTED/home-files/.config/systemd/user/ollama.service")"
      assertFileContains "$generated" "for model in llama2"
    '';
  };
}
