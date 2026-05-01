{ pkgs, ... }:
let
  src = pkgs.writeTextDir "agents/code-reviewer.agent.md" ''
    ---
    description: Review changes from a store-path directory fixture.
    tools: ["*"]
    ---

    Focus on correctness and missing coverage.
  '';

  skillsSrc = pkgs.writeTextDir "skills/external-skill/SKILL.md" ''
    ---
    name: external-skill
    description: Store-path directory fixture.
    ---

    Exercise top-level store-path directory handling.
  '';
in
{
  programs.github-copilot-cli = {
    enable = true;
    agents = "${src}/agents";
    skills = "${skillsSrc}/skills";
  };

  nmt.script = ''
    assertFileExists home-files/.copilot/agents/code-reviewer.agent.md
    assertLinkExists home-files/.copilot/agents/code-reviewer.agent.md
    assertFileContent home-files/.copilot/agents/code-reviewer.agent.md \
      "${src}/agents/code-reviewer.agent.md"

    assertFileExists home-files/.copilot/skills/external-skill/SKILL.md
    assertLinkExists home-files/.copilot/skills/external-skill/SKILL.md
    assertFileContent home-files/.copilot/skills/external-skill/SKILL.md \
      "${skillsSrc}/skills/external-skill/SKILL.md"
  '';
}
