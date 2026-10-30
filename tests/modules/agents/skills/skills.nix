{ config, pkgs, ... }:

let
  skillsPackage = config.lib.test.mkStubPackage {
    name = "skills-package";
    buildScript = ''
      mkdir -p $out/share/skills/skills-package/package-skill
      cat > $out/share/skills/skills-package/package-skill/SKILL.md <<'EOF'
      ---
      name: package-skill
      description: Skill from a package.
      ---
      EOF
    '';
  };

  storeSkill = pkgs.writeTextDir "skills/store-skill/SKILL.md" ''
    ---
    name: store-skill
    description: Skill from a store path.
    ---
  '';

  linkedSkill = pkgs.linkFarm "linked-skill" {
    "SKILL.md" = ./dir-skill/SKILL.md;
    "reference.md" = ./bundle/bundle-skill/reference.md;
  };
in
{
  agents.skills = {
    packages = [ skillsPackage ];
    bundles = [ ./bundle ];
    skills = {
      dir-skill.source = ./dir-skill;
      file-skill.source = ./FILE-SKILL.md;
      store-skill.source = "${storeSkill}/skills/store-skill";
      linked-skill.source = linkedSkill;
      disabled-skill = {
        enable = false;
        source = ./dir-skill;
      };
      text-skill.text = ''
        ---
        name: text-skill
        description: Skill from inline text.
        ---
      '';
    };
  };

  nmt.script = ''
    skills=home-files/.agents/skills

    assertDirectoryExists $skills
    if [[ -L $TESTED/$skills ]]; then
      fail "Expected $skills to not be a symlink."
    fi

    assertFileContent $skills/package-skill/SKILL.md \
      ${skillsPackage}/share/skills/skills-package/package-skill/SKILL.md
    assertFileContent $skills/bundle-skill/SKILL.md \
      ${./bundle/bundle-skill/SKILL.md}
    assertFileContent $skills/bundle-skill/reference.md \
      ${./bundle/bundle-skill/reference.md}
    assertPathNotExists $skills/README.md
    assertFileContent $skills/dir-skill/SKILL.md ${./dir-skill/SKILL.md}
    assertFileContent $skills/file-skill/SKILL.md ${./FILE-SKILL.md}
    assertFileContent $skills/store-skill/SKILL.md \
      ${storeSkill}/skills/store-skill/SKILL.md
    assertFileRegex $skills/text-skill/SKILL.md \
      '^description: Skill from inline text\.$'
    assertPathNotExists $skills/disabled-skill
    assertFileContent $skills/linked-skill/SKILL.md ${./dir-skill/SKILL.md}
    assertFileContent $skills/linked-skill/reference.md \
      ${./bundle/bundle-skill/reference.md}

    for skill in file-skill text-skill linked-skill; do
      assertLinkExists $skills/$skill
      for file in $TESTED/$skills/$skill/*; do
        if [[ -L $file ]]; then
          fail "Expected $file to not be a symlink."
        fi
      done
    done
  '';
}
