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
      dir-skill = ./skills-dir/skill-one;
    };
  };

  nmt.script = ''
    if [[ -L home-files/.codex/skills ]]; then
      fail "Expected home-files/.codex/skills to remain a normal directory so unmanaged skills can coexist."
    fi
    assertLinkExists home-files/.codex/skills/inline-skill
    assertFileExists home-files/.codex/skills/inline-skill/SKILL.md
    if [[ -L home-files/.codex/skills/inline-skill/SKILL.md ]]; then
      fail "Expected home-files/.codex/skills/inline-skill/SKILL.md to be a regular file inside a symlinked skill directory."
    fi
    assertFileContent home-files/.codex/skills/inline-skill/SKILL.md \
      ${builtins.toFile "expected-inline-skill.md" inlineSkill}
    assertLinkExists home-files/.codex/skills/file-skill
    assertFileExists home-files/.codex/skills/file-skill/SKILL.md
    if [[ -L home-files/.codex/skills/file-skill/SKILL.md ]]; then
      fail "Expected home-files/.codex/skills/file-skill/SKILL.md to be a regular file inside a symlinked skill directory."
    fi
    assertFileContent home-files/.codex/skills/file-skill/SKILL.md \
      ${./skill-file.md}
    assertLinkExists home-files/.codex/skills/dir-skill
    assertFileExists home-files/.codex/skills/dir-skill/SKILL.md
    if [[ -L home-files/.codex/skills/dir-skill/SKILL.md ]]; then
      fail "Expected home-files/.codex/skills/dir-skill/SKILL.md to be a regular file inside a symlinked skill directory."
    fi
    assertFileContent home-files/.codex/skills/dir-skill/SKILL.md \
      ${./skills-dir/skill-one/SKILL.md}
  '';
}
