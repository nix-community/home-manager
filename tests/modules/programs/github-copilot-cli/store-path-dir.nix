{ realPkgs, ... }:
let
  src = realPkgs.runCommand "github-copilot-cli-ifd-agents-directory" { } ''
    mkdir -p "$out/agents"
    echo '# Code Reviewer' > "$out/agents/code-reviewer.agent.md"
  '';

  skillsSrc = realPkgs.runCommand "github-copilot-cli-ifd-skills-directory" { } ''
    mkdir -p "$out/skills/external-skill"
    echo '# External Skill' > "$out/skills/external-skill/SKILL.md"
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
