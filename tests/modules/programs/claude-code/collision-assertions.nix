{ config, ... }:
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

    # An attribute set cannot hold duplicate names, so uniqueness can only be
    # violated by colliding with the generated Home Manager plugin, which is
    # present because `mcpServers` is set.
    mcpServers.github = {
      type = "http";
      url = "https://api.githubcopilot.com/mcp/";
    };
    plugins.claude-code-home-manager = ./test-plugin;
  };

  test.asserts.assertions.expected = [
    "`programs.claude-code.plugins` entries must resolve to unique personal-plugin directory names"
  ];
}
