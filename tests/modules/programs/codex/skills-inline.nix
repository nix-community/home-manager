{
  programs.codex = {
    enable = true;
    skills = {
      inline-skill = ''
        ---
        name: inline-skill
        description: Inline skill for tests.
        ---

        # Inline Skill

        Test fixture content.
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.codex/skills/inline-skill/SKILL.md
    assertFileRegex home-files/.codex/skills/inline-skill/SKILL.md "Inline Skill"
  '';
}
