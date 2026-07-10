{ config, pkgs, ... }:
let
  mkPackagePlugin =
    name:
    pkgs.runCommand "source" { } ''
      install -Dm644 ${
        pkgs.writeText "${name}.json" (
          builtins.toJSON {
            inherit name;
          }
        )
      } $out/.claude-plugin/plugin.json
    '';
  manifestlessPlugin = pkgs.runCommand "manifestless-plugin" { } ''
    install -Dm644 ${./test-command.md} $out/commands/test.md
  '';
  packagePluginOne = mkPackagePlugin "package-plugin-one";
  packagePluginTwo = mkPackagePlugin "package-plugin-two";
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

    plugins = [
      ./test-plugin
      packagePluginOne
      packagePluginTwo
      manifestlessPlugin
    ];
  };

  nmt.script = ''
    "$TESTED/home-path/bin/claude" rc
    assertPathNotExists "$TESTED/home-path/bin/.claude-wrapped"

    pluginDir="$TESTED/home-files/.claude/skills/${pluginDirName ./test-plugin}"
    assertFileContent "$pluginDir/.claude-plugin/plugin.json" ${./test-plugin/.claude-plugin/plugin.json}
    assertFileContains \
      "$TESTED/home-files/.claude/skills/${pluginDirName packagePluginOne}/.claude-plugin/plugin.json" \
      '"name":"package-plugin-one"'
    assertFileContains \
      "$TESTED/home-files/.claude/skills/${pluginDirName packagePluginTwo}/.claude-plugin/plugin.json" \
      '"name":"package-plugin-two"'
    assertFileContains \
      "$TESTED/home-files/.claude/skills/${pluginDirName manifestlessPlugin}/.claude-plugin/plugin.json" \
      '"name": "${pluginDirName manifestlessPlugin}"'
    assertFileContent \
      "$TESTED/home-files/.claude/skills/${pluginDirName manifestlessPlugin}/commands/test.md" \
      ${./test-command.md}
  '';
}
