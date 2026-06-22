{
  programs.github-copilot-cli = {
    enable = true;
    lspServers = {
      typescript = {
        command = "typescript-language-server";
        args = [ "--stdio" ];
        fileExtensions = {
          ".ts" = "typescript";
          ".tsx" = "typescriptreact";
          ".js" = "javascript";
          ".jsx" = "javascriptreact";
        };
      };
      python = {
        command = "pyright-langserver";
        args = [ "--stdio" ];
        fileExtensions = {
          ".py" = "python";
          ".pyw" = "python";
          ".pyi" = "python";
        };
        env = {
          PYTHONPATH = "\${PYTHONPATH:-}";
        };
        rootUri = "backend";
        requestTimeoutMs = 120000;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.copilot/lsp-config.json
    assertFileContent home-files/.copilot/lsp-config.json ${./expected-lsp-config.json}
    assertPathNotExists home-files/.copilot/config.json
    assertPathNotExists home-files/.copilot/mcp-config.json
  '';
}
