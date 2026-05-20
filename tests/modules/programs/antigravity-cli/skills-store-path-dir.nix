{ pkgs, ... }:

let
  src = pkgs.writeTextDir "skills/external-skill/SKILL.md" ''
    # External Skill
  '';
in
{
  programs.antigravity-cli = {
    enable = true;
    package = pkgs.writeShellScriptBin "antigravity-cli" "";
    skills = "${src}/skills";
  };

  nmt.script = ''
    assertFileExists home-files/.gemini/config/skills/external-skill/SKILL.md
    assertLinkExists home-files/.gemini/config/skills/external-skill/SKILL.md
    assertFileContent home-files/.gemini/config/skills/external-skill/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
  '';
}
