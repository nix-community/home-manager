{ config, ... }:
let
  codexPackage = config.lib.test.mkStubPackage {
    name = "codex";
    version = "0.93.0";
  };
in
{
  programs.codex = {
    enable = true;
    package = codexPackage;
    skills = {
      inline-skill = ''
        # Inline Skill
      '';
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
      ${builtins.toFile "expected-inline-skill.md" ''
        # Inline Skill
      ''}
  '';
}
