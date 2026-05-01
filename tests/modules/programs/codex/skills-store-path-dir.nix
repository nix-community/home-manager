{ pkgs, ... }:

let
  src = pkgs.writeTextDir "skills/external-skill/SKILL.md" ''
    ---
    name: external-skill
    description: Store path skill directory fixture.
    ---

    # External Skill
  '';
in
{
  programs.codex = {
    enable = true;
    skills = "${src}/skills";
  };

  nmt.script = ''
    assertLinkExists home-files/.codex/skills/external-skill
    assertFileExists home-files/.codex/skills/external-skill/SKILL.md
    assertFileContent home-files/.codex/skills/external-skill/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
  '';
}
