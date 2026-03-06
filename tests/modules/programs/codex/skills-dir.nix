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
    assertFileExists home-files/.agents/skills/skill-one/SKILL.md
    assertFileContent home-files/.agents/skills/skill-one/SKILL.md \
      ${./skills-dir/skill-one/SKILL.md}
  '';
}
