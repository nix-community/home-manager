{ pkgs, ... }:

let
  src = pkgs.writeTextDir "skills/external-skill/SKILL.md" ''
    # External Skill
  '';
in
{
  programs.gemini-cli = {
    enable = true;
    skills = "${src}/skills";
  };

  nmt.script = ''
    assertFileExists home-files/.gemini/skills/external-skill/SKILL.md
    assertLinkExists home-files/.gemini/skills/external-skill/SKILL.md
    assertFileContent home-files/.gemini/skills/external-skill/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
  '';
}
