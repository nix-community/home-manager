{
  programs.agent-skills = {
    enable = true;
    bundles = [
      ./shared-bundle
      ./override-bundle
    ];
    skills = {
      from-dir = ./single-skill;
      from-file = ./standalone/SKILL.md;
      from-inline = ''
        ---
        name: from-inline
        description: Inline skill defined via shared agent-skills.
        ---
      '';
    };
  };

  nmt.script = ''
    assertFileExists home-files/.agents/skills/shared-only/SKILL.md
    assertFileExists home-files/.agents/skills/shared-overridden/SKILL.md
    assertFileExists home-files/.agents/skills/from-dir/SKILL.md
    assertFileExists home-files/.agents/skills/from-file/SKILL.md
    assertFileExists home-files/.agents/skills/from-inline/SKILL.md

    assertFileRegex home-files/.agents/skills/shared-only/SKILL.md \
      'Shared skill exposed to every agent.'
    assertFileRegex home-files/.agents/skills/shared-overridden/SKILL.md \
      'Shared skill from the override bundle.'
    assertFileRegex home-files/.agents/skills/from-dir/SKILL.md \
      'Skill exposed via a single-skill directory.'
    assertFileRegex home-files/.agents/skills/from-file/SKILL.md \
      'Skill exposed via a direct SKILL.md file path.'
    assertFileRegex home-files/.agents/skills/from-inline/SKILL.md \
      'Inline skill defined via shared agent-skills.'
  '';
}
