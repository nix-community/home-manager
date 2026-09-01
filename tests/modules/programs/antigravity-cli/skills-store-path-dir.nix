{ pkgs, realPkgs, ... }:

let
  src = realPkgs.runCommand "antigravity-cli-ifd-skills-directory" { } ''
    mkdir -p "$out/skills/external-skill"
    echo '# External Skill' > "$out/skills/external-skill/SKILL.md"
  '';
in
{
  programs.antigravity-cli = {
    enable = true;
    package = pkgs.writeShellScriptBin "antigravity-cli" "";
    skills = "${src}/skills";
  };

  nmt.script = ''
    assertFileExists home-files/.gemini/antigravity-cli/skills/external-skill/SKILL.md
    assertLinkExists home-files/.gemini/antigravity-cli/skills/external-skill/SKILL.md
    assertFileContent home-files/.gemini/antigravity-cli/skills/external-skill/SKILL.md \
      "${src}/skills/external-skill/SKILL.md"
  '';
}
