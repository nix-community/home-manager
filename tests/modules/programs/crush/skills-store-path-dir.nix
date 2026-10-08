{ realPkgs, ... }:

let
  src = realPkgs.runCommand "crush-ifd-skills-directory" { } ''
    mkdir -p "$out/skills/external-skill"
    echo '# External Skill' > "$out/skills/external-skill/SKILL.md"
  '';
in
{
  programs.crush = {
    enable = true;
    package = null;
    skills = "${src}/skills";
  };

  nmt.script = ''
    assertFileExists home-files/.config/crush/skills/external-skill/SKILL.md
    assertLinkExists home-files/.config/crush/skills/external-skill/SKILL.md
    assertFileContent home-files/.config/crush/skills/external-skill/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
  '';
}
