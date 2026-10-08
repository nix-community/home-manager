{ realPkgs, ... }:

let
  src = realPkgs.runCommand "opencode-ifd-skills-directory" { } ''
    mkdir -p "$out/skills/external-skill"
    echo '# External Skill' > "$out/skills/external-skill/SKILL.md"
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
