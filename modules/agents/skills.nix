{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) literalExpression mkOption types;

  cfg = config.agents.skills;

  skillType = types.submodule (
    { name, config, ... }:
    {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Whether this skill should be installed.
          '';
        };

        text = mkOption {
          type = types.nullOr types.lines;
          default = null;
          description = ''
            Text of the skill's {file}`SKILL.md`. If this option is null
            then [](#opt-agents.skills.skills._name_.source) must be set.
          '';
        };

        source = mkOption {
          type = types.path;
          description = ''
            Path of the skill. Either a directory containing a
            {file}`SKILL.md` along with any supporting files, or a single
            file that is installed as the skill's {file}`SKILL.md`. If
            [](#opt-agents.skills.skills._name_.text) is non-null then this
            option will automatically point to a file containing that text.
          '';
        };
      };

      config.source = lib.mkIf (config.text != null) (
        lib.mkDefault (
          pkgs.writeTextFile {
            inherit (config) text;
            name = lib.hm.strings.storeFileName name;
          }
        )
      );
    }
  );

  enabledSkills = lib.filterAttrs (_: skill: skill.enable) cfg.skills;

  mkSkillDir =
    name: source:
    pkgs.runCommandLocal "agent-skill-${lib.strings.sanitizeDerivationName name}" { } ''
      source=${lib.escapeShellArg "${source}"}
      option=${lib.escapeShellArg "agents.skills.skills.${name}"}
      if [[ -d "$source" ]]; then
        cp -rL "$source" "$out"
      elif [[ -f "$source" ]]; then
        mkdir "$out"
        cp "$source" "$out/SKILL.md"
      else
        echo "agents.skills: $option must be a file or directory: $source" >&2
        exit 1
      fi
    '';

  skillsDir = pkgs.runCommandLocal "agent-skills" { } ''
    shopt -s nullglob
    mkdir "$out"

    addSkill() {
      local name="$1" skill="$2" origin="$3"
      if [[ -e "$out/$name" || -L "$out/$name" ]]; then
        echo "agents.skills: skill '$name' from $origin conflicts with an already defined skill" >&2
        exit 1
      fi
      ln -s "$skill" "$out/$name"
    }

    addBundle() {
      local bundle="$1" origin="$2" skill
      if [[ ! -d "$bundle" ]]; then
        echo "agents.skills: $origin is not a directory" >&2
        exit 1
      fi
      for skill in "$bundle"/*/; do
        skill="''${skill%/}"
        addSkill "$(basename "$skill")" "$skill" "$origin"
      done
    }

    addPackage() {
      local package="$1" base found=
      for base in "$package"/share/skills/*/; do
        found=1
        addBundle "''${base%/}" "package $package"
      done
      if [[ -z "$found" ]]; then
        echo "agents.skills: package $package provides no skills under share/skills" >&2
        exit 1
      fi
    }

    addSource() {
      addSkill "$1" "$2" "agents.skills.skills.$1"
    }

    ${lib.concatMapStrings (package: ''
      addPackage ${lib.escapeShellArg "${package}"}
    '') cfg.packages}
    ${lib.concatMapStrings (bundle: ''
      addBundle ${lib.escapeShellArg "${bundle}"} ${lib.escapeShellArg "bundle ${bundle}"}
    '') cfg.bundles}
    ${lib.concatStrings (
      lib.mapAttrsToList (name: skill: ''
        addSource ${lib.escapeShellArg name} ${lib.escapeShellArg "${mkSkillDir name skill.source}"}
      '') enabledSkills
    )}
  '';
in
{
  meta.maintainers = [ lib.maintainers.vidhanio ];

  options.agents.skills = {
    packages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      example = literalExpression "[ config.programs.worktrunk.package ]";
      description = ''
        Packages providing skills under
        {file}`share/skills/<base>/<skill>/`, following the nixpkgs
        `installAgentSkills` convention. Every skill of every listed
        package is installed.
      '';
    };

    bundles = mkOption {
      type = types.listOf types.path;
      default = [ ];
      example = literalExpression ''[ "''${inputs.my-skills}/skills" ]'';
      description = ''
        Directories whose top-level subdirectories are skills, each
        containing a {file}`SKILL.md`. The skill name is the name of the
        subdirectory. Top-level files, such as a {file}`README.md`, are
        ignored.
      '';
    };

    skills = mkOption {
      type = types.attrsOf skillType;
      default = { };
      example = literalExpression ''
        {
          comma.source = ./COMMA.md;
          meowland.source = ./meowland;
          inline.text = '''
            ---
            name: inline
            description: An inline skill.
            ---
          ''';
        }
      '';
      description = ''
        Named skills, each installed as
        {file}`~/.agents/skills/<name>`.
      '';
    };

    directory = mkOption {
      type = types.nullOr types.package;
      internal = true;
      readOnly = true;
      default =
        if cfg.packages != [ ] || cfg.bundles != [ ] || enabledSkills != { } then skillsDir else null;
      defaultText = literalExpression "null";
      description = ''
        Directory holding a symlink to every configured skill, or null if
        no skills are configured. Used by agent modules that do not read
        {file}`~/.agents/skills` themselves.
      '';
    };
  };

  config = lib.mkIf (cfg.directory != null) {
    home.file.".agents/skills" = {
      source = cfg.directory;
      recursive = true;
    };
  };
}
