{
  programs.pi-coding-agent = {
    enable = true;
    skills = ./skills-dir;
  };

  nmt.script = ''
    if [[ -L home-files/.pi/agent/skills ]]; then
      fail "Expected home-files/.pi/agent/skills to remain a normal directory so unmanaged skills can coexist."
    fi
    assertLinkExists home-files/.pi/agent/skills/skill-one
    assertFileExists home-files/.pi/agent/skills/skill-one/SKILL.md
    if [[ -L home-files/.pi/agent/skills/skill-one/SKILL.md ]]; then
      fail "Expected home-files/.pi/agent/skills/skill-one/SKILL.md to be a regular file inside a symlinked skill directory."
    fi
    assertFileContent home-files/.pi/agent/skills/skill-one/SKILL.md \
      ${./skills-dir/skill-one/SKILL.md}
  '';
}
