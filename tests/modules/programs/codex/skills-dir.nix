{ config, ... }:
let
  codexPackage = config.lib.test.mkStubPackage {
    name = "codex";
    version = "0.94.0";
  };
in
{
  programs.codex = {
    enable = true;
    package = codexPackage;
    skills = ./skills-dir;
  };

  nmt.script = ''
    if [[ -L home-files/.agents/skills ]]; then
      fail "Expected home-files/.agents/skills to remain a normal directory so unmanaged skills can coexist."
    fi
    assertLinkExists home-files/.agents/skills/skill-one
    assertFileExists home-files/.agents/skills/skill-one/SKILL.md
    if [[ -L home-files/.agents/skills/skill-one/SKILL.md ]]; then
      fail "Expected home-files/.agents/skills/skill-one/SKILL.md to be a regular file inside a symlinked skill directory."
    fi
    assertFileContent home-files/.agents/skills/skill-one/SKILL.md \
      ${./skills-dir/skill-one/SKILL.md}
  '';
}
