{ lib, pkgs }:
let
  # TODO: Remove this workaround once Codex supports symlinked SKILL.md
  # files again. Upstream only supports symlinking the containing skill
  # directory today: https://github.com/openai/codex/issues/10470
  mkSkillDir =
    content:
    if lib.isPath content then
      pkgs.writeTextDir "SKILL.md" (builtins.readFile content)
    else if lib.hm.strings.isPathLike content then
      pkgs.runCommandLocal "codex-skill" { } ''
        source=${lib.escapeShellArg "${content}"}
        if [[ -d "$source" ]]; then
          ln -s "$source" "$out"
        elif [[ -f "$source" ]]; then
          mkdir -p "$out"
          cp "$source" "$out/SKILL.md"
        else
          echo "Codex skill source '$source' is neither a file nor a directory" >&2
          exit 1
        fi
      ''
    else
      pkgs.writeTextDir "SKILL.md" content;

  canInspect =
    value:
    !lib.isDerivation value
    && lib.all (context: context.path or false) (lib.attrValues (builtins.getContext (toString value)));

  mkPluginName =
    plugin:
    let
      manifestPath = plugin + "/.codex-plugin/plugin.json";
      manifestName =
        if canInspect plugin && builtins.pathExists manifestPath then
          (builtins.fromJSON (builtins.readFile manifestPath)).name
        else
          null;
      fallbackName =
        if lib.isDerivation plugin then
          plugin.pname or (lib.getName plugin)
        else
          baseNameOf (toString plugin);
    in
    builtins.unsafeDiscardStringContext (if manifestName != null then manifestName else fallbackName);

  mkPluginVersion =
    plugin:
    let
      manifestPath = plugin + "/.codex-plugin/plugin.json";
      manifestVersion =
        if canInspect plugin && builtins.pathExists manifestPath then
          (builtins.fromJSON (builtins.readFile manifestPath)).version or null
        else
          null;
      fallbackVersion = plugin.version or "0.0.0";
    in
    builtins.unsafeDiscardStringContext (
      if manifestVersion != null then manifestVersion else fallbackVersion
    );

  sanitizePathComponent =
    value: builtins.unsafeDiscardStringContext (lib.strings.sanitizeDerivationName value);

  mkPluginPathName = plugin: sanitizePathComponent (mkPluginName plugin);
  mkPluginPathVersion = plugin: sanitizePathComponent (mkPluginVersion plugin);
in
{
  needsBuildTimePluginIdentity = plugin: !lib.isDerivation plugin && !canInspect plugin;

  mkSkillSources =
    skills:
    if !lib.hm.strings.isPathLike skills && builtins.isAttrs skills then
      skills
    else if lib.isPath skills && lib.pathIsDirectory skills then
      lib.mapAttrs (name: _type: skills + "/${name}") (builtins.readDir skills)
    else
      { };

  mkHelpers =
    {
      configDir,
      homeRelativePluginsCacheDir,
      pluginsCacheDir,
      pluginsMarketplaceName,
      skillsDir,
      tomlFormat,
    }:
    let
      mkCheckedDirectory =
        name: source:
        if lib.isPath source then
          source
        else
          pkgs.runCommandLocal "codex-${lib.strings.sanitizeDerivationName name}" { } ''
            source=${lib.escapeShellArg "${source}"}
            if [[ ! -d "$source" ]]; then
              echo "Codex ${name} source '$source' is not a directory" >&2
              exit 1
            fi
            ln -s "$source" "$out"
          '';

      mkCheckedFile =
        name: source:
        if lib.isPath source then
          source
        else
          pkgs.runCommandLocal "codex-${lib.strings.sanitizeDerivationName name}" { } ''
            source=${lib.escapeShellArg "${source}"}
            if [[ ! -f "$source" ]]; then
              echo "Codex ${name} source '$source' is not a file" >&2
              exit 1
            fi
            ln -s "$source" "$out"
          '';

      mkPluginCachePath =
        plugin:
        "${pluginsCacheDir}/${pluginsMarketplaceName}/${mkPluginPathName plugin}/${mkPluginPathVersion plugin}";
    in
    {
      inherit mkPluginCachePath;

      mkMarketplaceConfigEntry = name: content: {
        source_type = "local";
        source = "${mkCheckedDirectory "marketplace-${name}" content}";
      };

      mkPersonalMarketplacePluginEntry = plugin: {
        name = mkPluginName plugin;
        source = {
          source = "local";
          path = "./${homeRelativePluginsCacheDir}/${pluginsMarketplaceName}/${mkPluginPathName plugin}/${mkPluginPathVersion plugin}";
        };
        policy = {
          installation = "AVAILABLE";
          authentication = "ON_INSTALL";
        };
        category = "Productivity";
      };

      mkPluginConfigEntry =
        plugin:
        lib.nameValuePair "${mkPluginName plugin}@${pluginsMarketplaceName}" {
          enabled = true;
        };

      mkPluginFileEntry =
        plugin:
        lib.nameValuePair (mkPluginCachePath plugin) {
          source = mkCheckedDirectory "plugin-${mkPluginPathName plugin}" plugin;
          force = true;
        };

      mkProfileEntry =
        name: settings:
        lib.nameValuePair "${configDir}/${name}.config.toml" {
          source = tomlFormat.generate "codex-${name}-config" settings;
        };

      mkRuleEntry =
        name: content:
        lib.nameValuePair "${configDir}/rules/${name}.rules" (
          if lib.hm.strings.isPathLike content then
            { source = mkCheckedFile "rule-${name}" content; }
          else
            { text = content; }
        );

      mkSkillEntry =
        name: content:
        lib.nameValuePair "${skillsDir}/${name}" {
          source = if lib.isPath content && lib.pathIsDirectory content then content else mkSkillDir content;
        };

      mkTextOrPathEntry =
        path: content:
        if lib.isPath content then
          lib.nameValuePair path { source = content; }
        else
          lib.nameValuePair path (lib.mkIf (content != "") { text = content; });
    };
}
