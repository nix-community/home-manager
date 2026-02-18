{ config, ... }:

let
  skill = config.lib.test.mkStubPackage {
    name = "mock-skill";

    buildScript = ''
      mkdir -p $out/supporting-files

      echo "# Mock skill" > $out/SKILL.md
      echo "This skill was built as a derivation." >> $out/SKILL.md

      echo "# Some supporting file" > $out/supporting-files/another-file.md
    '';
  };
in
{
  programs.opencode = {
    enable = true;
    skills = {
      skill-from-derivation = skill;
      skill-from-string = "${skill}";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/opencode/skill/skill-from-derivation/SKILL.md
    assertFileExists home-files/.config/opencode/skill/skill-from-derivation/supporting-files/another-file.md
    assertFileContent home-files/.config/opencode/skill/skill-from-derivation/SKILL.md \
      "${skill}/SKILL.md"
    assertFileContent home-files/.config/opencode/skill/skill-from-derivation/supporting-files/another-file.md \
      "${skill}/supporting-files/another-file.md"

    assertFileExists home-files/.config/opencode/skill/skill-from-string/SKILL.md
    assertFileExists home-files/.config/opencode/skill/skill-from-string/supporting-files/another-file.md
    assertFileContent home-files/.config/opencode/skill/skill-from-string/SKILL.md \
      "${skill}/SKILL.md"
    assertFileContent home-files/.config/opencode/skill/skill-from-string/supporting-files/another-file.md \
      "${skill}/supporting-files/another-file.md"
  '';
}
