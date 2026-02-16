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
  programs.codex = {
    enable = true;
    skills = {
      inline-skill = inlineSkill;
      file-skill = ./skill-file.md;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.codex/skills/inline-skill/SKILL.md
    assertFileContent home-files/.codex/skills/inline-skill/SKILL.md \
      ${builtins.toFile "expected-inline-skill.md" inlineSkill}
    assertFileExists home-files/.codex/skills/file-skill/SKILL.md
    assertFileContent home-files/.codex/skills/file-skill/SKILL.md \
      ${./skill-file.md}
  '';
}
