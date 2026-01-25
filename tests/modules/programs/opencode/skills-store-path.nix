{ pkgs, ... }:

let
  src = pkgs.writeTextDir "skills/external-skill/SKILL.md" ''
    # Mock Skill
    This content simulates a skill living inside a package source.
  '';
in
{
  programs.opencode = {
    enable = true;
    skills = {
      # We reference the specific subfolder inside the store path
      internal-skill = "${src}/skills/external-skill";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/opencode/skill/internal-skill/SKILL.md

    assertFileContent home-files/.config/opencode/skill/internal-skill/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
  '';
}
