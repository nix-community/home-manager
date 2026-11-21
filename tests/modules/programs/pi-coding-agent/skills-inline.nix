let
  inlineSkill = ''
    ---
    name: inline-skill
    description: Inline skill for tests.
    ---

    # Inline Skill

    Test fixture content.
  '';
in
{
  programs.pi-coding-agent = {
    enable = true;
    skills = {
      inline-skill = inlineSkill;
      file-skill = ./skill-file.md;
      dir-skill = ./skills-dir/skill-one;
    };
  };

  nmt.script = ''
    if [[ -L home-files/.pi/agent/skills ]]; then
      fail "Expected home-files/.pi/agent/skills to remain a normal directory so unmanaged skills can coexist."
    fi
    assertLinkExists home-files/.pi/agent/skills/inline-skill
    assertFileExists home-files/.pi/agent/skills/inline-skill/SKILL.md
    if [[ -L home-files/.pi/agent/skills/inline-skill/SKILL.md ]]; then
      fail "Expected home-files/.pi/agent/skills/inline-skill/SKILL.md to be a regular file inside a symlinked skill directory."
    fi
    assertFileContent home-files/.pi/agent/skills/inline-skill/SKILL.md \
      ${builtins.toFile "expected-inline-skill.md" inlineSkill}
    assertLinkExists home-files/.pi/agent/skills/file-skill
    assertFileExists home-files/.pi/agent/skills/file-skill/SKILL.md
    if [[ -L home-files/.pi/agent/skills/file-skill/SKILL.md ]]; then
      fail "Expected home-files/.pi/agent/skills/file-skill/SKILL.md to be a regular file inside a symlinked skill directory."
    fi
    assertFileContent home-files/.pi/agent/skills/file-skill/SKILL.md \
      ${./skill-file.md}
    assertLinkExists home-files/.pi/agent/skills/dir-skill
    assertFileExists home-files/.pi/agent/skills/dir-skill/SKILL.md
    if [[ -L home-files/.pi/agent/skills/dir-skill/SKILL.md ]]; then
      fail "Expected home-files/.pi/agent/skills/dir-skill/SKILL.md to be a regular file inside a symlinked skill directory."
    fi
    assertFileContent home-files/.pi/agent/skills/dir-skill/SKILL.md \
      ${./skills-dir/skill-one/SKILL.md}
  '';
}
