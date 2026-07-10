{ lib, pkgs }:
let
  jsonFormat = pkgs.formats.json { };
in
{
  mkHelpers =
    { configDir }:
    let
      mkSourceEntry = content: if lib.isPath content then { source = content; } else { text = content; };

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
          lib.nameValuePair "${configDir}/hooks/${name}" {
            text = content;
            executable = true;
          }
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

      mkPluginEntry =
        plugin:
        let
          name = builtins.unsafeDiscardStringContext (
            lib.strings.sanitizeDerivationName (baseNameOf (toString plugin))
          );
        in
        {
          inherit name;
          source = pkgs.symlinkJoin {
            name = "claude-code-${name}";
            paths = [ plugin ];
            postBuild = ''
              if [[ ! -e $out/.claude-plugin/plugin.json ]]; then
                install -Dm644 ${
                  jsonFormat.generate "claude-code-${name}.json" {
                    inherit name;
                  }
                } $out/.claude-plugin/plugin.json
              fi
            '';
          };
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
        if lib.hm.strings.isPathLike content && lib.pathIsDirectory content then
          lib.nameValuePair "${configDir}/skills/${name}" {
            source = content;
            recursive = true;
          }
        else
          lib.nameValuePair "${configDir}/skills/${name}/SKILL.md" (
            if lib.hm.strings.isPathLike content then { source = content; } else { text = content; }
          );
    };
}
