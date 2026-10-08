{ realPkgs, ... }:

let
  src = realPkgs.runCommand "github-copilot-cli-ifd-skill-source" { } ''
    mkdir -p "$out/skills/external-skill"
    echo '# External Skill' > "$out/skills/external-skill/SKILL.md"
  '';
in
{
  programs.github-copilot-cli = {
    enable = true;
    skills = {
      directory = "${src}/skills/external-skill";
      file = "${src}/skills/external-skill/SKILL.md";
    };
  };

  nmt.script = ''
    assertFileContent home-files/.copilot/skills/directory/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
    assertFileContent home-files/.copilot/skills/file/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
  '';
}
