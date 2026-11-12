{ realPkgs, ... }:
let
  src = realPkgs.runCommand "pi-coding-agent-ifd-skill-source" { } ''
    mkdir -p "$out/skills/external-skill"
    echo '# External Skill' > "$out/skills/external-skill/SKILL.md"
  '';
in
{
  programs.pi-coding-agent = {
    enable = true;
    skills = {
      dir-skill = "${src}/skills/external-skill";
      file-skill = "${src}/skills/external-skill/SKILL.md";
    };
  };

  nmt.script = ''
    assertLinkExists home-files/.pi/agent/skills/dir-skill
    assertFileExists home-files/.pi/agent/skills/dir-skill/SKILL.md
    assertFileContent home-files/.pi/agent/skills/dir-skill/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"

    assertLinkExists home-files/.pi/agent/skills/file-skill
    assertFileExists home-files/.pi/agent/skills/file-skill/SKILL.md
    assertFileContent home-files/.pi/agent/skills/file-skill/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
  '';
}
