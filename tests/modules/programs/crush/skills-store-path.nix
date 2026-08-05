{ realPkgs, ... }:

let
  src = realPkgs.runCommand "crush-ifd-skill-source" { } ''
    mkdir -p "$out/skills/external-skill"
    echo '# External Skill' > "$out/skills/external-skill/SKILL.md"
  '';
in
{
  programs.crush = {
    enable = true;
    package = null;
    skills = {
      directory = "${src}/skills/external-skill";
      file = "${src}/skills/external-skill/SKILL.md";
    };
  };

  nmt.script = ''
    assertFileContent home-files/.config/crush/skills/directory/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
    assertFileContent home-files/.config/crush/skills/file/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
  '';
}
