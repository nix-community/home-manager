{ realPkgs, ... }:

let
  src = realPkgs.runCommand "claude-code-ifd-skills-directory" { } ''
    mkdir -p "$out/skills/external-skill"
    echo '# External Skill' > "$out/skills/external-skill/SKILL.md"
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
