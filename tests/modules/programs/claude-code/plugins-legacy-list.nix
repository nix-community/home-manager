{ config, pkgs, ... }:
let
  pluginDirName = plugin: baseNameOf (toString plugin);
in

{
  programs.claude-code = {
    package = config.lib.test.mkStubPackage {
      name = "claude-code";
      version = "2.1.197";
      buildScript = ''
        mkdir -p $out/bin
        cat > $out/bin/claude <<'EOF'
        #!${pkgs.runtimeShell}
        test "$#" -eq 1
        test "$1" = rc
        EOF
        chmod +x $out/bin/claude
      '';
    };
    enable = true;

    plugins = [ ./test-plugin ];
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

  nmt.script = ''
    "$TESTED/home-path/bin/claude" rc

    # The list form still derives the directory name from the entry's base name.
    pluginDir="$TESTED/home-files/.claude/skills/${pluginDirName ./test-plugin}"
    assertLinkExists "home-files/.claude/skills/${pluginDirName ./test-plugin}"
    assertFileContent "$pluginDir/.claude-plugin/plugin.json" ${./test-plugin/.claude-plugin/plugin.json}
    assertFileContent \
      "$pluginDir/agents/test-plugin-agent.md" \
      ${./test-plugin/agents/test-plugin-agent.md}
  '';
}
