{ pkgs, ... }:

{
  programs.antigravity-cli = {
    enable = true;
    package = pkgs.writeShellScriptBin "antigravity-cli" "";
    plugins = {
      standard = ./plugins/standard-plugin;
      untrusted = ./plugins/security-plugin;
      trusted = {
        source = ./plugins/security-plugin;
        allowHooks = true;
        allowMcp = true;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.gemini/config/plugins/standard/plugin.json
    assertFileContent home-files/.gemini/config/plugins/standard/plugin.json \
      ${./plugins/standard-plugin/plugin.json}

    assertFileExists home-files/.gemini/config/plugins/standard/rules/AGENTS.md
    assertFileContent home-files/.gemini/config/plugins/standard/rules/AGENTS.md \
      ${./plugins/standard-plugin/rules/AGENTS.md}

    assertFileExists home-files/.gemini/config/plugins/standard/skills/helper/SKILL.md
    assertFileContent home-files/.gemini/config/plugins/standard/skills/helper/SKILL.md \
      ${./plugins/standard-plugin/skills/helper/SKILL.md}

    # Untrusted plugin: rules and agents hoist, but hooks.json and mcp_config.json must NOT be copied
    assertFileExists home-files/.gemini/config/plugins/untrusted/rules/AGENTS.md
    assertFileExists home-files/.gemini/config/plugins/untrusted/agents/security-agent.md
    assertPathNotExists home-files/.gemini/config/plugins/untrusted/hooks.json
    assertPathNotExists home-files/.gemini/config/plugins/untrusted/mcp_config.json

    # Trusted plugin: rules, agents, hooks.json, and mcp_config.json are all present
    assertFileExists home-files/.gemini/config/plugins/trusted/rules/AGENTS.md
    assertFileExists home-files/.gemini/config/plugins/trusted/agents/security-agent.md
    assertFileExists home-files/.gemini/config/plugins/trusted/hooks.json
    assertFileExists home-files/.gemini/config/plugins/trusted/mcp_config.json
  '';
}
