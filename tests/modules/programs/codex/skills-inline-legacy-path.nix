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
    assertFileExists home-files/.codex/skills/inline-skill/SKILL.md
    assertFileContent home-files/.codex/skills/inline-skill/SKILL.md \
      ${builtins.toFile "expected-inline-skill.md" ''
        # Inline Skill
      ''}
  '';
}
