{ config, ... }:
let
  plugin = ./test-plugin;
  pluginDirName = baseNameOf (toString plugin);
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
    plugins = [
      plugin
      plugin
    ];
    skills.${pluginDirName} = "test skill";
  };

  test.asserts.assertions.expected = [
    "`programs.claude-code.plugins` entries must resolve to unique personal-plugin directory names"
    "`programs.claude-code.skills` and managed plugins must have unique directory names"
  ];
}
