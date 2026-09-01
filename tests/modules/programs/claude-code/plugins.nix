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

    plugins = {
      test-plugin = ./test-plugin;
      package-plugin-one = mkPackagePlugin "package-plugin-one";
      package-plugin-two = mkPackagePlugin "package-plugin-two";
      manifestless = manifestlessPlugin;
    };
  };

  nmt.script = ''
    "$TESTED/home-path/bin/claude" rc
    assertPathNotExists "$TESTED/home-path/bin/.claude-wrapped"

    # Each plugin must be linked as a single directory symlink. Linking
    # recursively materializes a real directory holding one symlink per file,
    # which makes Claude Code skip every agent and command the plugin ships.
    assertLinkExists "home-files/.claude/skills/test-plugin"
    assertLinkExists "home-files/.claude/skills/package-plugin-one"
    assertLinkExists "home-files/.claude/skills/manifestless"

    pluginDir="$TESTED/home-files/.claude/skills/test-plugin"
    assertFileContent "$pluginDir/.claude-plugin/plugin.json" ${./test-plugin/.claude-plugin/plugin.json}
    assertFileContent \
      "$pluginDir/agents/test-plugin-agent.md" \
      ${./test-plugin/agents/test-plugin-agent.md}
    assertFileContent \
      "$pluginDir/commands/test-plugin-command.md" \
      ${./test-plugin/commands/test-plugin-command.md}

    # Claude Code lists a plugin's agents and commands with a `readdir` that
    # accepts only regular files, so these must not be per-file symlinks.
    # `assertFileContent` follows symlinks and cannot catch this on its own.
    for componentFile in \
      "$pluginDir/agents/test-plugin-agent.md" \
      "$pluginDir/commands/test-plugin-command.md"; do
      if [[ -L "$componentFile" ]]; then
        echo "Plugin component must be a regular file, not a symlink: $componentFile"
        exit 1
      fi
    done

    assertFileContains \
      "$TESTED/home-files/.claude/skills/package-plugin-one/.claude-plugin/plugin.json" \
      '"name":"package-plugin-one"'
    assertFileContains \
      "$TESTED/home-files/.claude/skills/package-plugin-two/.claude-plugin/plugin.json" \
      '"name":"package-plugin-two"'
    assertFileContains \
      "$TESTED/home-files/.claude/skills/manifestless/.claude-plugin/plugin.json" \
      '"name": "manifestless"'
    assertFileContent \
      "$TESTED/home-files/.claude/skills/manifestless/commands/test.md" \
      ${./test-command.md}
  '';
}
