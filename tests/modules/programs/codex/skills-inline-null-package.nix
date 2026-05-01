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
    assertLinkExists home-files/.codex/skills/inline-skill
    assertFileExists home-files/.codex/skills/inline-skill/SKILL.md
    if [[ -L home-files/.codex/skills/inline-skill/SKILL.md ]]; then
      fail "Expected home-files/.codex/skills/inline-skill/SKILL.md to be a regular file inside a symlinked skill directory."
    fi
    assertFileContent home-files/.codex/skills/inline-skill/SKILL.md \
      ${builtins.toFile "expected-inline-skill.md" ''
        # Inline Skill
      ''}
  '';
}
