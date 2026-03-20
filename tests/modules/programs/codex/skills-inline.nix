{ config, ... }:
let
  codexPackage = config.lib.test.mkStubPackage {
    name = "codex";
    version = "0.94.0";
  };
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
    package = codexPackage;
    skills = {
      inline-skill = inlineSkill;
      file-skill = ./skill-file.md;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.agents/skills/inline-skill/SKILL.md
    assertFileContent home-files/.agents/skills/inline-skill/SKILL.md \
      ${builtins.toFile "expected-inline-skill.md" inlineSkill}
    assertFileExists home-files/.agents/skills/file-skill/SKILL.md
    assertFileContent home-files/.agents/skills/file-skill/SKILL.md \
      ${./skill-file.md}
  '';
}
