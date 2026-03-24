{ pkgs, ... }:
let
  src = pkgs.writeTextDir "skills/external-skill/SKILL.md" ''
    ---
    name: external-skill
    description: Store path skill fixture.
    ---

    # External Skill

    This content simulates a skill living inside a package source.
  '';
in
{
  programs.codex = {
    enable = true;
    skills = {
      dir-skill = "${src}/skills/external-skill";
      file-skill = "${src}/skills/external-skill/SKILL.md";
    };
  };

  nmt.script = ''
    assertLinkExists home-files/.agents/skills/dir-skill
    assertFileExists home-files/.agents/skills/dir-skill/SKILL.md
    assertFileContent home-files/.agents/skills/dir-skill/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"

    assertLinkExists home-files/.agents/skills/file-skill
    assertFileExists home-files/.agents/skills/file-skill/SKILL.md
    assertFileContent home-files/.agents/skills/file-skill/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
  '';
}
