{
  programs.dprint = {
    enable = true;
    settings = {
      excludes = [ "**/*-lock.json" ];
      json = {
        indentWidth = 2;
      };
      lineWidth = 80;
      plugins = [
        "https://plugins.dprint.dev/typescript-0.96.1.wasm"
        "https://plugins.dprint.dev/json-0.23.0.wasm"
        "https://plugins.dprint.dev/markdown-0.22.1.wasm"
      ];
      typescript = {
        "binaryExpression.operatorPosition" = "sameLine";
        quoteStyle = "preferSingle";
      };
    };
  };
  nmt.script = ''
    assertFileContent \
      home-files/.config/dprint/dprint.json \
      ${./expected-dprint.json}
  '';
}
