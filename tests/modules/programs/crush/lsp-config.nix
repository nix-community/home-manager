{
  programs.crush = {
    enable = true;

    settings.lsp = {
      go = {
        command = "gopls";
        env = {
          GOTOOLCHAIN = "go1.24.5";
        };
      };
      typescript = {
        command = "typescript-language-server";
        args = [ "--stdio" ];
      };
      nix = {
        command = "nil";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/crush/crush.json
    assertFileContent home-files/.config/crush/crush.json ${./expected-lsp-config.json}
  '';
}
