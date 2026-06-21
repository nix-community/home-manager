{ lib, pkgs }:
let
  # TODO: Remove this workaround once Codex supports symlinked SKILL.md
  # files again. Upstream only supports symlinking the containing skill
  # directory today: https://github.com/openai/codex/issues/10470
  mkSkillDir =
    content:
    pkgs.writeTextDir "SKILL.md" (
      if lib.hm.strings.isPathLike content then builtins.readFile content else content
    );

  mkPluginName =
    plugin:
    let
      manifestPath = plugin + "/.codex-plugin/plugin.json";
      manifestName =
        if !lib.isDerivation plugin && builtins.pathExists manifestPath then
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
        if !lib.isDerivation plugin && builtins.pathExists manifestPath then
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
  mkSkillSources =
    skills:
    if builtins.isAttrs skills then
      skills
    else if lib.hm.strings.isPathLike skills && lib.pathIsDirectory skills then
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
      mkPluginCachePath =
        plugin:
        "${pluginsCacheDir}/${pluginsMarketplaceName}/${mkPluginPathName plugin}/${mkPluginPathVersion plugin}";
    in
    {
      inherit mkPluginCachePath;

      mkMarketplaceConfigEntry = _name: content: {
        source_type = "local";
        source = "${content}";
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
          source = plugin;
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
          if lib.hm.strings.isPathLike content then { source = content; } else { text = content; }
        );

      mkSkillEntry =
        name: content:
        if lib.hm.strings.isPathLike content && lib.pathIsDirectory content then
          lib.nameValuePair "${skillsDir}/${name}" {
            source = content;
          }
        else
          lib.nameValuePair "${skillsDir}/${name}" {
            source = mkSkillDir content;
          };

      mkTextOrPathEntry =
        path: content:
        if lib.isPath content then
          lib.nameValuePair path { source = content; }
        else
          lib.nameValuePair path (lib.mkIf (content != "") { text = content; });
    };
}
