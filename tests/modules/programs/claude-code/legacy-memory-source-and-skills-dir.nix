{ lib, options, ... }:

{
  programs.claude-code = {
    enable = true;
    memory.source = ./expected-memory.md;
    skillsDir = ./skills;
  };

  test.asserts.warnings.expected = [
    "The option `programs.claude-code.skillsDir' defined in ${lib.showFiles options.programs.claude-code.skillsDir.files} has been changed to `programs.claude-code.skills' that has a different type. Please read `programs.claude-code.skills' documentation and update your configuration accordingly."
    "The option `programs.claude-code.memory.source' defined in ${lib.showFiles options.programs.claude-code.memory.source.files} has been changed to `programs.claude-code.context' that has a different type. Please read `programs.claude-code.context' documentation and update your configuration accordingly."
  ];

  nmt.script = ''
    assertFileExists home-files/.claude/CLAUDE.md
    assertFileContent home-files/.claude/CLAUDE.md ${./expected-memory.md}

    assertFileExists home-files/.claude/skills/test-skill/SKILL.md
    assertLinkExists home-files/.claude/skills/test-skill/SKILL.md
    assertFileContent \
      home-files/.claude/skills/test-skill/SKILL.md \
      ${./skills/test-skill/SKILL.md}
  '';
}
