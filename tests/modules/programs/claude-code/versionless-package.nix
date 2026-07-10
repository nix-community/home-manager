{ config, ... }:

{
  programs.claude-code = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "claude-code";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/claude
        chmod 755 $out/bin/claude
      '';
    };
    plugins = [ ./test-plugin ];
  };

  test.asserts.warnings.expected = [
    ''
      `programs.claude-code.package` has no detectable version and
      uses the legacy `--plugin-dir` wrapper. Strict-parser subcommands such
      as `claude rc` may reject managed MCP, LSP, or plugin arguments. Upgrade
      Claude Code to version 2.1.157 or later to use persistent personal
      plugins instead.
    ''
  ];

  nmt.script = ''
    wrapperPath="$TESTED/home-path/bin/claude"
    normalizedWrapper=$(normalizeStorePaths "$wrapperPath")
    assertFileContent "$normalizedWrapper" ${./expected-plugin-wrapper}
  '';
}
