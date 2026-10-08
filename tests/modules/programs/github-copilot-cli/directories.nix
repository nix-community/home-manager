{
  programs.github-copilot-cli = {
    enable = true;
    agents = ./agents;
    skills = ./skills;
  };

  nmt.script = ''
    assertFileExists home-files/.copilot/agents/code-reviewer.agent.md
    assertLinkExists home-files/.copilot/agents/code-reviewer.agent.md
    assertFileContent home-files/.copilot/agents/code-reviewer.agent.md \
      ${./agents/code-reviewer.agent.md}

    assertFileExists home-files/.copilot/agents/documentation.agent.md
    assertLinkExists home-files/.copilot/agents/documentation.agent.md
    assertFileContent home-files/.copilot/agents/documentation.agent.md \
      ${./agents/documentation.agent.md}

    assertFileExists home-files/.copilot/skills/data-analysis/SKILL.md
    assertFileExists home-files/.copilot/skills/data-analysis/notes.txt
    assertLinkExists home-files/.copilot/skills/data-analysis/SKILL.md
    assertLinkExists home-files/.copilot/skills/data-analysis/notes.txt
    assertFileContent home-files/.copilot/skills/data-analysis/SKILL.md \
      ${./skills/data-analysis/SKILL.md}
    assertFileContent home-files/.copilot/skills/data-analysis/notes.txt \
      ${./skills/data-analysis/notes.txt}

    assertFileExists home-files/.copilot/skills/release-notes/SKILL.md
    assertFileExists home-files/.copilot/skills/release-notes/checklist.md
    assertLinkExists home-files/.copilot/skills/release-notes/SKILL.md
    assertLinkExists home-files/.copilot/skills/release-notes/checklist.md
    assertFileContent home-files/.copilot/skills/release-notes/SKILL.md \
      ${./skills/release-notes/SKILL.md}
    assertFileContent home-files/.copilot/skills/release-notes/checklist.md \
      ${./skills/release-notes/checklist.md}
  '';
}
