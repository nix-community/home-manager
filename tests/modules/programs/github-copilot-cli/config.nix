{ pkgs, ... }:
let
  inlineAgent = ''
    ---
    description: Review staged changes for bugs and test gaps.
    tools: ["*"]
    ---

    Report only actionable findings.
  '';
  storeAgentSrc = pkgs.writeText "code-reviewer.agent.md" ''
    ---
    description: Review changes for bugs and missing tests.
    tools: ["*"]
    ---

    Report actionable findings only.
  '';
  inlineSkill = ''
    ---
    name: inline-skill
    description: Inline skill fixture for Copilot CLI tests.
    ---

    Use this skill when validating inline skill materialization.
  '';
  inlineContext = ''
    Review the repository before making changes.
    Report only actionable findings.
  '';
  storeSkillSrc = pkgs.writeTextDir "skills/external-skill/SKILL.md" ''
    # External Skill
  '';
in
{
  programs.github-copilot-cli = {
    enable = true;
    settings = {
      model = "claude-sonnet-4-5";
      theme = "dark";
      trusted_folders = [ "/home/user/projects" ];
    };
    context = inlineContext;
    agents = {
      inline-reviewer = inlineAgent;
      path-reviewer = ./agents/documentation.agent.md;
      store-reviewer = "${storeAgentSrc}";
    };
    skills = {
      inline-skill = inlineSkill;
      path-skill = ./test-skill.md;
      dir-skill = ./skills/data-analysis;
      store-skill = "${storeSkillSrc}/skills/external-skill";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.copilot/config.json
    assertFileContent home-files/.copilot/config.json ${./expected-config.json}

    assertFileExists home-files/.copilot/copilot-instructions.md
    assertFileContent home-files/.copilot/copilot-instructions.md \
      ${builtins.toFile "expected-copilot-instructions.md" inlineContext}

    assertFileExists home-files/.copilot/agents/inline-reviewer.agent.md
    assertFileContent home-files/.copilot/agents/inline-reviewer.agent.md \
      ${builtins.toFile "expected-inline-reviewer.agent.md" inlineAgent}

    assertFileExists home-files/.copilot/agents/path-reviewer.agent.md
    assertLinkExists home-files/.copilot/agents/path-reviewer.agent.md
    assertFileContent home-files/.copilot/agents/path-reviewer.agent.md \
      ${./agents/documentation.agent.md}

    assertFileExists home-files/.copilot/agents/store-reviewer.agent.md
    assertLinkExists home-files/.copilot/agents/store-reviewer.agent.md
    assertFileContent home-files/.copilot/agents/store-reviewer.agent.md \
      ${storeAgentSrc}

    assertFileExists home-files/.copilot/skills/inline-skill/SKILL.md
    assertFileContent home-files/.copilot/skills/inline-skill/SKILL.md \
      ${builtins.toFile "expected-inline-skill.md" inlineSkill}

    assertFileExists home-files/.copilot/skills/path-skill/SKILL.md
    assertLinkExists home-files/.copilot/skills/path-skill/SKILL.md
    assertFileContent home-files/.copilot/skills/path-skill/SKILL.md \
      ${./test-skill.md}

    assertFileExists home-files/.copilot/skills/dir-skill/SKILL.md
    assertFileExists home-files/.copilot/skills/dir-skill/notes.txt
    assertLinkExists home-files/.copilot/skills/dir-skill/SKILL.md
    assertLinkExists home-files/.copilot/skills/dir-skill/notes.txt
    assertFileContent home-files/.copilot/skills/dir-skill/SKILL.md \
      ${./skills/data-analysis/SKILL.md}
    assertFileContent home-files/.copilot/skills/dir-skill/notes.txt \
      ${./skills/data-analysis/notes.txt}

    assertFileExists home-files/.copilot/skills/store-skill/SKILL.md
    assertLinkExists home-files/.copilot/skills/store-skill/SKILL.md
    assertFileContent home-files/.copilot/skills/store-skill/SKILL.md \
      "${storeSkillSrc}/skills/external-skill/SKILL.md"

    assertPathNotExists home-files/.copilot/mcp-config.json
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'COPILOT_HOME'
  '';
}
