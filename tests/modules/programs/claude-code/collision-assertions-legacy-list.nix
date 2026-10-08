{ config, ... }:
let
  plugin = ./test-plugin;
in
{
  programs.claude-code = {
    enable = true;
    package = config.lib.test.mkStubPackage {
      name = "claude-code";
      version = "2.1.157";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/claude
        chmod 755 $out/bin/claude
      '';
    };
    # Two list entries can derive the same directory name.
    plugins = [
      plugin
      plugin
    ];
  };

  test.asserts.warnings.expected = [
    ''
      `programs.claude-code.plugins` is set to a list. Names are then derived
      from each entry's base name, which for store paths yields unstable
      directory names such as `bxa1s0m3h4sh-source`. Use an attribute set
      instead so plugin directory names stay stable and readable:

        plugins.my-plugin = ./my-plugin;
    ''
  ];

  test.asserts.assertions.expected = [
    "`programs.claude-code.plugins` entries must resolve to unique personal-plugin directory names"
  ];
}
