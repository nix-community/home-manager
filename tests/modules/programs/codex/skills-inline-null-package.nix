{
  programs.codex = {
    enable = true;
    package = null;
    skills = {
      inline-skill = ''
        # Inline Skill
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.agents/skills/inline-skill/SKILL.md
    assertFileContent home-files/.agents/skills/inline-skill/SKILL.md \
      ${builtins.toFile "expected-inline-skill.md" ''
        # Inline Skill
      ''}
  '';
}
