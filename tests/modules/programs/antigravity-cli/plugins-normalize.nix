{ pkgs, ... }:

{
  programs.antigravity-cli = {
    enable = true;
    package = pkgs.writeShellScriptBin "antigravity-cli" "";
    plugins = {
      foreign = ./plugins/foreign-plugin;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.gemini/config/plugins/foreign/plugin.json
    assertFileRegex home-files/.gemini/config/plugins/foreign/plugin.json \
      '"name"[[:space:]]*:[[:space:]]*"foreign"'

    assertFileExists home-files/.gemini/config/plugins/foreign/rules/AGENTS.md
    assertFileContent home-files/.gemini/config/plugins/foreign/rules/AGENTS.md \
      ${./plugins/foreign-plugin/AGENTS.md}

    assertFileExists home-files/.gemini/config/plugins/foreign/skills/bloat-audit/SKILL.md
    assertFileContent home-files/.gemini/config/plugins/foreign/skills/bloat-audit/SKILL.md \
      ${./plugins/foreign-plugin/skills/bloat-audit/SKILL.md}

    assertFileExists home-files/.gemini/config/plugins/foreign/agents/reviewer.md
    assertFileContent home-files/.gemini/config/plugins/foreign/agents/reviewer.md \
      ${./plugins/foreign-plugin/agents/reviewer.md}
  '';
}
