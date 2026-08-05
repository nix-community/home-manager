{ pkgs, realPkgs, ... }:

let
  src = realPkgs.runCommand "antigravity-cli-ifd-skill-source" { } ''
    mkdir -p "$out/skills/external-skill"
    echo '# External Skill' > "$out/skills/external-skill/SKILL.md"
  '';
in
{
  programs.antigravity-cli = {
    enable = true;
    package = pkgs.writeShellScriptBin "antigravity-cli" "";
    skills = {
      directory = "${src}/skills/external-skill";
      file = "${src}/skills/external-skill/SKILL.md";
    };
  };

  nmt.script = ''
    assertFileContent home-files/.gemini/antigravity-cli/skills/directory/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
    assertFileContent home-files/.gemini/antigravity-cli/skills/file/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
  '';
}
