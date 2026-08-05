{ lib, pkgs }:
let
  jsonFormat = pkgs.formats.json { };
in
{
  mkHelpers =
    { configDir }:
    let
      mkSourceEntry =
        content: if lib.hm.strings.isPathLike content then { source = content; } else { text = content; };

      mkMarketplaceEntry = _name: content: {
        source = {
          source = "directory";
          path = content;
        };
      };
    in
    {
      inherit mkMarketplaceEntry;

      mkHookEntries =
        attrs:
        lib.mapAttrs' (
          name: content:
          lib.nameValuePair "${configDir}/hooks/${name}" ((mkSourceEntry content) // { executable = true; })
        ) attrs;

      mkInstalledMarketplaceEntry =
        name: content:
        (mkMarketplaceEntry name content)
        // {
          installLocation = content;
          lastUpdated = "1970-01-01T00:00:00Z";
        };

      mkMarkdownEntries =
        subdir: attrs:
        lib.mapAttrs' (
          name: content: lib.nameValuePair "${configDir}/${subdir}/${name}.md" (mkSourceEntry content)
        ) attrs;

      # Legacy list entries have no user-supplied name, so derive one from the
      # source's base name. Store paths yield unstable names like
      # `bxa1s0m3h4sh-source`, which is why the attribute set form is preferred.
      derivePluginName =
        plugin:
        builtins.unsafeDiscardStringContext (
          lib.strings.sanitizeDerivationName (baseNameOf (toString plugin))
        );

      # Wraps a plugin so a manifest can be synthesized for sources that lack
      # one. Only top-level entries are linked, leaving each component
      # directory a single symlink to the original. `pkgs.symlinkJoin` cannot
      # be used here: it mirrors directories and symlinks the leaf files, and
      # Claude Code's `agents/` and `commands/` scanners accept only regular
      # files, so every agent and command would be dropped.
      mkPluginEntry = name: plugin: {
        inherit name;
        source = pkgs.runCommand "claude-code-${name}" { } ''
          mkdir -p "$out"

          shopt -s dotglob nullglob
          for entry in "${plugin}"/*; do
            ln -s "$entry" "$out/$(basename "$entry")"
          done

          if [[ ! -e $out/.claude-plugin/plugin.json ]]; then
            # Replace the linked manifest directory with a real one so the
            # generated manifest can sit beside any existing contents.
            rm -f "$out/.claude-plugin"
            mkdir -p "$out/.claude-plugin"
            for entry in "${plugin}"/.claude-plugin/*; do
              ln -s "$entry" "$out/.claude-plugin/$(basename "$entry")"
            done
            install -m644 ${
              jsonFormat.generate "claude-code-${name}.json" {
                inherit name;
              }
            } "$out/.claude-plugin/plugin.json"
          fi
        '';
      };

      mkRecursiveDirAttrs =
        subdir: dir:
        lib.optionalAttrs (dir != null) {
          "${configDir}/${subdir}" = {
            source = dir;
            recursive = true;
          };
        };

      mkSkillEntry =
        name: content:
        if lib.isPath content && lib.pathIsDirectory content then
          lib.nameValuePair "${configDir}/skills/${name}" {
            source = content;
            recursive = true;
          }
        else if lib.isPath content then
          lib.nameValuePair "${configDir}/skills/${name}/SKILL.md" { source = content; }
        else if lib.hm.strings.isPathLike content then
          lib.nameValuePair "${configDir}/skills/${name}" {
            source = pkgs.runCommandLocal "claude-code-skill-${lib.strings.sanitizeDerivationName name}" { } ''
              source=${lib.escapeShellArg "${content}"}
              if [[ -d "$source" ]]; then
                ln -s "$source" "$out"
              elif [[ -f "$source" ]]; then
                mkdir -p "$out"
                ln -s "$source" "$out/SKILL.md"
              else
                echo "Claude Code skill source '$source' is neither a file nor a directory" >&2
                exit 1
              fi
            '';
            recursive = true;
          }
        else
          lib.nameValuePair "${configDir}/skills/${name}/SKILL.md" {
            text = content;
          };
    };
}
