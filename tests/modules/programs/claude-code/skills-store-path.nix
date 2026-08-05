{ realPkgs, ... }:

let
  src = realPkgs.runCommand "claude-code-ifd-skill-source" { } ''
    mkdir -p "$out/skills/external-skill"
    echo '# External Skill' > "$out/skills/external-skill/SKILL.md"
  '';
in
{
  programs.claude-code = {
    enable = true;
    skills = {
      directory = "${src}/skills/external-skill";
      file = "${src}/skills/external-skill/SKILL.md";
    };
  };

  nmt.script = ''
    assertFileContent home-files/.claude/skills/directory/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
    assertFileContent home-files/.claude/skills/file/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
  '';
}
