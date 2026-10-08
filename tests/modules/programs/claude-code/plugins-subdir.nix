{ pkgs, ... }:

let
  # Mimics a fetched repository that holds plugins in subdirectories
  # alongside unrelated repository content. One subdirectory contains
  # whitespace, which must survive the wrapper's glob expansion.
  # Claude Code rejects plugin names containing spaces, so the manifest name
  # stays kebab-case while the directory holding it does not.
  repo = pkgs.runCommand "claude-plugin-repo" { } ''
    mkPlugin() {
      local dir="$1" name="$2"
      mkdir -p "$out/plugins/$dir/.claude-plugin" "$out/plugins/$dir/agents"
      echo "{\"name\":\"$name\",\"version\":\"1.0.0\"}" \
        > "$out/plugins/$dir/.claude-plugin/plugin.json"
      cat > "$out/plugins/$dir/agents/$name-agent.md" <<EOF
    ---
    name: $name-agent
    description: Agent provided by a plugin nested in a repository
    ---

    Agent body.
    EOF
    }

    mkPlugin "nested-plugin" "nested-plugin"
    mkPlugin "spaced plugin" "spaced-plugin"
    echo '# Repository readme' > "$out/README.md"
  '';
in
{
  programs.claude-code = {
    enable = true;
    plugins = {
      nested-plugin = "${repo}/plugins/nested-plugin";
      spaced-plugin = "${repo}/plugins/spaced plugin";
    };
  };

  nmt.script = ''
    assertLinkExists "home-files/.claude/skills/nested-plugin"
    assertLinkExists "home-files/.claude/skills/spaced-plugin"

    nestedDir="$TESTED/home-files/.claude/skills/nested-plugin"
    assertFileContent \
      "$nestedDir/.claude-plugin/plugin.json" \
      "${repo}/plugins/nested-plugin/.claude-plugin/plugin.json"
    assertFileContent \
      "$nestedDir/agents/nested-plugin-agent.md" \
      "${repo}/plugins/nested-plugin/agents/nested-plugin-agent.md"

    # A source path containing whitespace must not be split during glob
    # expansion, which would leave dangling links and drop plugin contents.
    spacedDir="$TESTED/home-files/.claude/skills/spaced-plugin"
    assertFileContent \
      "$spacedDir/.claude-plugin/plugin.json" \
      "${repo}/plugins/spaced plugin/.claude-plugin/plugin.json"
    assertFileContent \
      "$spacedDir/agents/spaced-plugin-agent.md" \
      "${repo}/plugins/spaced plugin/agents/spaced-plugin-agent.md"

    for pluginDir in "$nestedDir" "$spacedDir"; do
      # Only the plugin subdirectory is linked, not the enclosing repository.
      assertPathNotExists "$pluginDir/README.md"
      assertPathNotExists "$pluginDir/plugins"

      # Every linked entry must resolve; a split path yields dangling links.
      for entry in "$pluginDir"/* "$pluginDir"/.[!.]*; do
        if [[ -e "$entry" ]]; then
          continue
        fi
        echo "Linked plugin entry does not resolve: $entry"
        exit 1
      done

      # Agents must stay regular files or Claude Code's scanner skips them.
      for agentFile in "$pluginDir"/agents/*.md; do
        if [[ -L "$agentFile" ]]; then
          echo "Plugin component must be a regular file, not a symlink: $agentFile"
          exit 1
        fi
      done
    done
  '';
}
