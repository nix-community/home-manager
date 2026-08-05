{ realPkgs, ... }:

let
  src = realPkgs.runCommand "opencode-ifd-skill-source" { } ''
    mkdir -p "$out/skills/external-skill"
    echo '# External Skill' > "$out/skills/external-skill/SKILL.md"
  '';
in
{
  programs.opencode = {
    enable = true;
    skills = {
      directory = "${src}/skills/external-skill";
      file = "${src}/skills/external-skill/SKILL.md";
    };
  };

  nmt.script = ''
    assertFileContent home-files/.config/opencode/skills/directory/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
    assertFileContent home-files/.config/opencode/skills/file/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
  '';
}
