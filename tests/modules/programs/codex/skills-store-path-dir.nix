{ realPkgs, ... }:

let
  src = realPkgs.runCommand "codex-ifd-skills-directory" { } ''
    mkdir -p "$out/skills/external-skill"
    echo '# External Skill' > "$out/skills/external-skill/SKILL.md"
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
