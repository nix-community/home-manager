{ pkgs, ... }:

let
  src = pkgs.writeTextDir "skills/external-skill/SKILL.md" ''
    # External Skill
  '';
in
{
  programs.opencode = {
    enable = true;
    skills = "${src}/skills";
  };

  nmt.script = ''
    assertFileExists home-files/.config/opencode/skills/external-skill/SKILL.md
    assertLinkExists home-files/.config/opencode/skills/external-skill/SKILL.md
    assertFileContent home-files/.config/opencode/skills/external-skill/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
  '';
}
