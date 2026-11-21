{ realPkgs, ... }:

let
  src = realPkgs.runCommand "pi-coding-agent-ifd-skills-directory" { } ''
    mkdir -p "$out/skills/external-skill"
    echo '# External Skill' > "$out/skills/external-skill/SKILL.md"
  '';
in
{
  programs.pi-coding-agent = {
    enable = true;
    skills = "${src}/skills";
  };

  nmt.script = ''
    assertLinkExists home-files/.pi/agent/skills/external-skill
    assertFileExists home-files/.pi/agent/skills/external-skill/SKILL.md
    assertFileContent home-files/.pi/agent/skills/external-skill/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
  '';
}
