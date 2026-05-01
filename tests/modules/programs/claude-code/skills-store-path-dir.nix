{ pkgs, ... }:

let
  src = pkgs.writeTextDir "skills/external-skill/SKILL.md" ''
    # External Skill
  '';
in
{
  programs.claude-code = {
    enable = true;
    skills = "${src}/skills";
  };

  nmt.script = ''
    assertFileExists home-files/.claude/skills/external-skill/SKILL.md
    assertLinkExists home-files/.claude/skills/external-skill/SKILL.md
    assertFileContent home-files/.claude/skills/external-skill/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
  '';
}
