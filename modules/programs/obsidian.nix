{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    mkPackageOption
    mkDefault
    literalExpression
    types
    ;

  cfg = config.programs.obsidian;

  corePluginsList = [
    "audio-recorder"
    "backlink"
    "bases"
    "bookmarks"
    "canvas"
    "command-palette"
    "daily-notes"
    "editor-status"
    "file-explorer"
    "file-recovery"
    "footnotes"
    "global-search"
    "graph"
    "markdown-importer"
    "note-composer"
    "outgoing-link"
    "outline"
    "page-preview"
    "properties"
    "publish"
    "random-note"
    "slash-command"
    "slides"
    "switcher"
    "sync"
    "tag-pane"
    "templates"
    "webviewer"
    "word-count"
    "workspaces"
    "zk-prefixer"
  ];

  appSettingsType = with types; nullOr (attrsOf anything);

  appearanceSettingsType = with types; nullOr (attrsOf anything);

  corePluginsOptions = {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable the plugin.";
      };

      name = mkOption {
        type = types.enum corePluginsList;
        description = "The plugin.";
      };

      settings = mkOption {
        type = with types; nullOr (attrsOf anything);
        description = "Plugin settings to include.";
        default = null;
      };
    };
  };
  corePluginsSettingsType =
    with types;
    nullOr (
      listOf (coercedTo (enum corePluginsList) (p: { name = p; }) (submodule corePluginsOptions))
    );

  communityPluginsOptions = {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable the plugin.";
      };

      pkg = mkOption {
        type = types.package;
        description = "The plugin package.";
      };

      settings = mkOption {
        type = with types; nullOr (attrsOf anything);
        description = "Settings to include in the plugin's `data.json`.";
        default = null;
      };
    };
  };
  communityPluginsSettingsType =
    with types;
    nullOr (listOf (coercedTo package (p: { pkg = p; }) (submodule communityPluginsOptions)));

  checkCssPath = path: lib.filesystem.pathIsRegularFile path && lib.strings.hasSuffix ".css" path;
  toCssName = path: lib.strings.removeSuffix ".css" (baseNameOf path);
  cssSnippetsOptions =
    { config, ... }:
    {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to enable the snippet.";
        };

        name = mkOption {
          type = types.str;
          defaultText = literalExpression ''lib.strings.removeSuffix ".css" (builtins.baseNameOf source)'';
          description = "Name of the snippet.";
        };

        source = mkOption {
          type = with types; nullOr (addCheck path checkCssPath);
          description = "Path of the source file.";
          default = null;
        };

        text = mkOption {
          type = with types; nullOr str;
          description = "Text of the file.";
          default = null;
        };
      };

      config.name = mkDefault (toCssName config.source);
    };
  cssSnippetsSettingsType =
    with types;
    nullOr (
      listOf (coercedTo (addCheck path checkCssPath) (p: { source = p; }) (submodule cssSnippetsOptions))
    );

  themesOptions = {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to set the theme as active.";
      };

      pkg = mkOption {
        type = types.package;
        description = "The theme package.";
      };
    };
  };
  themesSettingsType =
    with types;
    nullOr (listOf (coercedTo package (p: { pkg = p; }) (submodule themesOptions)));

  hotkeysOptions = {
    options = {
      modifiers = mkOption {
        type = with types; listOf str;
        description = "The hotkey modifiers.";
        default = [ ];
      };

      key = mkOption {
        type = types.str;
        description = "The hotkey.";
      };
    };
  };
  hotkeysSettingsType = with types; nullOr (attrsOf (listOf (submodule hotkeysOptions)));

  extraFilesOptions =
    { name, config, ... }:
    {
      options = {
        source = mkOption {
          type = with types; nullOr path;
          description = "Path of the source file or directory.";
          default = null;
        };

        text = mkOption {
          type = with types; nullOr str;
          description = "Text of the file.";
          default = null;
        };

        target = mkOption {
          type = types.str;
          defaultText = literalExpression "name";
          description = "Path to target relative to the vault's directory.";
        };
      };

      config.target = mkDefault name;
    };
  extraFilesSettingsType = with types; nullOr (attrsOf (submodule extraFilesOptions));
in
{
  meta.maintainers = [ lib.hm.maintainers.karaolidis ];

  options.programs.obsidian = {
    enable = mkEnableOption "obsidian";
    package = mkPackageOption pkgs "obsidian" { nullable = true; };

    defaultSettings = {
      app = mkOption {
        description = ''
          Settings to write to `app.json`.

          Vault-specific settings take priority and will override these, if set.
        '';
        type = appSettingsType;
        default = null;
      };

      appearance = mkOption {
        description = ''
          Settings to write to `appearance.json`.

          Vault-specific settings take priority and will override these, if set.
        '';
        type = appearanceSettingsType;
        default = null;
      };

      corePlugins = mkOption {
        description = ''
          Core plugins to activate.

          Vault-specific settings take priority and will override these, if set.
        '';
        type = corePluginsSettingsType;
        default = null;
      };

      communityPlugins = mkOption {
        description = "
          Community plugins to install and activate.

          Vault-specific settings take priority and will override these, if set.
        ";
        type = communityPluginsSettingsType;
        default = null;
      };

      cssSnippets = mkOption {
        description = "
          CSS snippets to install.

          Vault-specific settings take priority and will override these, if set.
        ";
        type = cssSnippetsSettingsType;
        default = null;
      };

      themes = mkOption {
        description = "
          Themes to install.

          Vault-specific settings take priority and will override these, if set.
        ";
        type = themesSettingsType;
        default = null;
      };

      hotkeys = mkOption {
        description = "
          Hotkeys to configure.

          Vault-specific settings take priority and will override these, if set.
        ";
        type = hotkeysSettingsType;
        default = null;
      };

      extraFiles = mkOption {
        description = "
          Extra files to link to the vault directory.

          Vault-specific settings take priority and will override these, if set.
        ";
        type = extraFilesSettingsType;
        default = null;
      };
    };

    vaults = mkOption {
      description = "List of vaults to create.";
      type = types.attrsOf (
        types.submodule (
          { name, config, ... }:
          {
            options = {
              enable = mkOption {
                type = types.bool;
                default = true;
                description = "Whether this vault should be generated.";
              };

              target = mkOption {
                type = types.str;
                defaultText = literalExpression "name";
                description = "Path to target vault relative to the user's {env}`HOME`.";
              };

              settings = {
                app = mkOption {
                  description = "Settings to write to app.json.";
                  type = appSettingsType;
                  default = cfg.defaultSettings.app;
                  defaultText = literalExpression "config.programs.obsidian.defaultSettings.app";
                };

                appearance = mkOption {
                  description = "Settings to write to appearance.json.";
                  type = appearanceSettingsType;
                  default = cfg.defaultSettings.appearance;
                  defaultText = literalExpression "config.programs.obsidian.defaultSettings.appearance";
                };

                corePlugins = mkOption {
                  description = "Core plugins to activate.";
                  type = corePluginsSettingsType;
                  default = cfg.defaultSettings.corePlugins;
                  defaultText = literalExpression "config.programs.obsidian.defaultSettings.corePlugins";
                };

                communityPlugins = mkOption {
                  description = "Community plugins to install and activate.";
                  type = communityPluginsSettingsType;
                  default = cfg.defaultSettings.communityPlugins;
                  defaultText = literalExpression "config.programs.obsidian.defaultSettings.communityPlugins";
                };

                cssSnippets = mkOption {
                  description = "CSS snippets to install.";
                  type = cssSnippetsSettingsType;
                  default = cfg.defaultSettings.cssSnippets;
                  defaultText = literalExpression "config.programs.obsidian.defaultSettings.cssSnippets";
                };

                themes = mkOption {
                  description = "Themes to install.";
                  type = themesSettingsType;
                  default = cfg.defaultSettings.themes;
                  defaultText = literalExpression "config.programs.obsidian.defaultSettings.themes";
                };

                hotkeys = mkOption {
                  description = "Hotkeys to configure.";
                  type = hotkeysSettingsType;
                  default = cfg.defaultSettings.hotkeys;
                  defaultText = literalExpression "config.programs.obsidian.defaultSettings.hotkeys";
                };

                extraFiles = mkOption {
                  description = "Extra files to link to the vault directory.";
                  type = extraFilesSettingsType;
                  default = cfg.defaultSettings.extraFiles;
                  defaultText = literalExpression "config.programs.obsidian.defaultSettings.extraFiles";
                };
              };
            };

            config.target = mkDefault name;
          }
        )
      );
      default = { };
    };
  };

  config =
    let
      vaults = builtins.filter (vault: vault.enable == true) (builtins.attrValues cfg.vaults);
      getManifest =
        item:
        let
          manifest = builtins.fromJSON (builtins.readFile "${item.pkg}/manifest.json");
        in
        manifest.id or manifest.name;
    in
    lib.mkIf cfg.enable {
      home = {
        packages = lib.mkIf (cfg.package != null) [ cfg.package ];

        file =
          let
            mkApp =
              vault:
              lib.lists.optionals (vault.settings.app != null) [
                {
                  name = "${vault.target}/.obsidian/app.json";
                  value.source = (pkgs.formats.json { }).generate "app.json" vault.settings.app;
                }
              ];

            mkAppearance =
              vault:
              lib.lists.optionals
                (
                  vault.settings.appearance != null
                  || vault.settings.themes != null
                  || vault.settings.cssSnippets != null
                )
                [
                  {
                    name = "${vault.target}/.obsidian/appearance.json";
                    value = {
                      source = (pkgs.formats.json { }).generate "appearance.json" (
                        (lib.attrsets.optionalAttrs (vault.settings.appearance != null) vault.settings.appearance)
                        // (lib.attrsets.optionalAttrs (vault.settings.cssSnippets != null) {
                          enabledCssSnippets = map (snippet: snippet.name) (
                            builtins.filter (snippet: snippet.enable) vault.settings.cssSnippets
                          );
                        })
                        // (lib.attrsets.optionalAttrs (vault.settings.themes != null) (
                          let
                            activeTheme = lib.lists.findSingle (
                              theme: theme.enable
                            ) null (throw "Only one theme can be enabled at a time.") vault.settings.themes;
                          in
                          lib.attrsets.optionalAttrs (activeTheme != null) {
                            cssTheme = getManifest activeTheme;
                          }
                        ))
                      );
                    };
                  }
                ];

            mkCorePlugins =
              vault:
              lib.lists.optionals (vault.settings.corePlugins != null) (
                [
                  {
                    name = "${vault.target}/.obsidian/core-plugins.json";
                    value.source = (pkgs.formats.json { }).generate "core-plugins.json" (
                      builtins.listToAttrs (
                        map (name: {
                          inherit name;
                          value = builtins.any (plugin: name == plugin.name && plugin.enable) vault.settings.corePlugins;
                        }) corePluginsList
                      )
                    );
                  }
                ]
                ++ map (plugin: {
                  name = "${vault.target}/.obsidian/${plugin.name}.json";
                  value.source = (pkgs.formats.json { }).generate "${plugin.name}.json" plugin.settings;
                }) (builtins.filter (plugin: plugin.settings != null) vault.settings.corePlugins)
              );

            mkCommunityPlugins =
              vault:
              lib.lists.optionals (vault.settings.communityPlugins != null) (
                [
                  {
                    name = "${vault.target}/.obsidian/community-plugins.json";
                    value.source = (pkgs.formats.json { }).generate "community-plugins.json" (
                      map getManifest (builtins.filter (plugin: plugin.enable) vault.settings.communityPlugins)
                    );
                  }
                ]
                ++ map (plugin: {
                  name = "${vault.target}/.obsidian/plugins/${getManifest plugin}";
                  value = {
                    source = plugin.pkg;
                    recursive = true;
                  };
                }) vault.settings.communityPlugins
                ++ map (plugin: {
                  name = "${vault.target}/.obsidian/plugins/${getManifest plugin}/data.json";
                  value.source = (pkgs.formats.json { }).generate "data.json" plugin.settings;
                }) (builtins.filter (plugin: plugin.settings != null) vault.settings.communityPlugins)
              );

            mkCssSnippets =
              vault:
              lib.lists.optionals (vault.settings.cssSnippets != null) (
                map (snippet: {
                  name = "${vault.target}/.obsidian/snippets/${snippet.name}.css";
                  value =
                    if snippet.source != null then
                      {
                        inherit (snippet) source;
                      }
                    else
                      {
                        inherit (snippet) text;
                      };
                }) vault.settings.cssSnippets
              );

            mkThemes =
              vault:
              lib.lists.optionals (vault.settings.themes != null) (
                map (theme: {
                  name = "${vault.target}/.obsidian/themes/${getManifest theme}";
                  value.source = theme.pkg;
                }) vault.settings.themes
              );

            mkHotkeys =
              vault:
              lib.lists.optionals (vault.settings.hotkeys != null) [
                {
                  name = "${vault.target}/.obsidian/hotkeys.json";
                  value.source = (pkgs.formats.json { }).generate "hotkeys.json" vault.settings.hotkeys;
                }
              ];

            mkExtraFiles =
              vault:
              lib.lists.optionals (vault.settings.extraFiles != null) (
                map (file: {
                  name = "${vault.target}/.obsidian/${file.target}";
                  value =
                    if file.source != null then
                      {
                        inherit (file) source;
                      }
                    else
                      {
                        inherit (file) text;
                      };
                }) (builtins.attrValues vault.settings.extraFiles)
              );
          in
          builtins.listToAttrs (
            lib.lists.flatten (
              map (vault: [
                (mkApp vault)
                (mkAppearance vault)
                (mkCorePlugins vault)
                (mkCommunityPlugins vault)
                (mkCssSnippets vault)
                (mkThemes vault)
                (mkHotkeys vault)
                (mkExtraFiles vault)
              ]) vaults
            )
          );

        activation.obsidian =
          let
            template = (pkgs.formats.json { }).generate "obsidian.json" {
              vaults = builtins.listToAttrs (
                map (vault: {
                  name = builtins.substring 0 16 (builtins.hashString "md5" vault.target);
                  value = {
                    path = "${config.home.homeDirectory}/${vault.target}";
                  };
                }) vaults
              );
              updateDisabled = true;
            };
          in
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            OBSIDIAN_CONFIG="$HOME/.config/obsidian/obsidian.json"
            if [ -f "$OBSIDIAN_CONFIG" ]; then
              verboseEcho "Merging existing Obsidian config with generated template"
              tmp="$(mktemp)"
              run ${lib.getExe pkgs.jq} -s '(.[0] // {}) * (.[1] // {})' "$OBSIDIAN_CONFIG" "${template}" > "$tmp"
              run install -m644 "$tmp" "$OBSIDIAN_CONFIG"
              rm -f "$tmp"
            else
              verboseEcho "Installing fresh Obsidian config"
              run install -D -m644 "${template}" "$OBSIDIAN_CONFIG"
            fi
          '';
      };

      assertions = [
        {
          assertion = builtins.all (
            vault:
            builtins.all (
              snippet:
              (snippet.source == null || snippet.text == null) && (snippet.source != null || snippet.text != null)
            ) (lib.lists.optionals (vault.settings.cssSnippets != null) vault.settings.cssSnippets)
          ) (builtins.attrValues cfg.vaults);
          message = "Each CSS snippet must have one of 'source' or 'text' set";
        }
        {
          assertion = builtins.all (
            vault:
            builtins.all
              (file: (file.source == null || file.text == null) && (file.source != null || file.text != null))
              (
                lib.lists.optionals (vault.settings.extraFiles != null) (
                  builtins.attrValues vault.settings.extraFiles
                )
              )
          ) (builtins.attrValues cfg.vaults);
          message = "Each extra file must have one of 'source' or 'text' set";
        }
      ];
    };
}
