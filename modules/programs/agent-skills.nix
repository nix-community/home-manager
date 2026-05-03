{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkEnableOption
    mkOption
    ;

  cfg = config.programs.agent-skills;

  mkSkillEntry =
    name: content:
    let
      target = ".agents/skills/${name}";
    in
    if lib.isPath content && lib.pathIsDirectory content then
      lib.nameValuePair target (
        lib.mkDefault {
          source = content;
          recursive = true;
        }
      )
    else
      lib.nameValuePair target (
        lib.mkDefault {
          source = pkgs.writeTextDir "SKILL.md" (
            if lib.isPath content then builtins.readFile content else content
          );
        }
      );
in
{
  meta.maintainers = with lib.maintainers; [ sei40kr ];

  options.programs.agent-skills = {
    enable = mkEnableOption "shared agent skills configuration";

    bundles = mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = ''
        List of skill bundle directories. Each entry is a directory
        whose top-level subdirectories are themselves skill
        directories; the skill name is taken from each
        subdirectory's basename.

        Bundles are merged in list order and later entries win on
        name conflicts. Entries from {option}`skills` further
        override these.
      '';
      example = literalExpression ''
        [
          ./skills/local-bundle
          ./skills/another-bundle
        ]
      '';
    };

    skills = mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.path lib.types.str);
      default = { };
      description = ''
        Named skills, keyed by skill name. Each value is one of:

        - A path to a {file}`SKILL.md` file.
        - A path to a single skill directory.
        - Inline string content used as the {file}`SKILL.md` body.

        Entries here override entries from {option}`bundles` on
        name conflicts.
      '';
      example = literalExpression ''
        {
          xlsx = ./skills/xlsx;
          named = ./skills/named/SKILL.md;
          inline = '''
            ---
            name: inline
            description: Inline skill.
            ---
          ''';
        }
      '';
    };

    skillEntries = mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.path lib.types.str);
      internal = true;
      readOnly = true;
      default =
        lib.foldl' (
          acc: bundle: acc // lib.mapAttrs (name: _kind: bundle + "/${name}") (builtins.readDir bundle)
        ) { } cfg.bundles
        // cfg.skills;
      defaultText = literalExpression "<flattened skill entries>";
      description = ''
        Flattened skill entries from {option}`bundles` and
        {option}`skills`. Materialized under
        {file}`~/.agents/skills/` for agents that auto-discover
        that location, and consumed by per-agent modules that need
        their own materialization via their own
        `enableSkillsIntegration` flag.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = lib.mapAttrs' mkSkillEntry cfg.skillEntries;
  };
}
