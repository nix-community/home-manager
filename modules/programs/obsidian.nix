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

  corePlugins = [
    "audio-recorder"
    "backlink"
    "bookmarks"
    "canvas"
    "command-palette"
    "daily-notes"
    "editor-status"
    "file-explorer"
    "file-recovery"
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
    "word-count"
    "workspaces"
    "zk-prefixer"
  ];
in
{
  options.programs.obsidian = {
    enable = mkEnableOption "obsidian";
    package = mkPackageOption pkgs "obsidian" { };

    defaultSettings = {
      app = mkOption {
        description = ''
          Settings to write to `app.json`.

          Vault-specific settings take priority and will override these, if set.
        '';
        type = types.raw;
        default = { };
      };

      appearance = mkOption {
        description = ''
          Settings to write to `appearance.json`.

          Vault-specific settings take priority and will override these, if set.
        '';
        type = types.raw;
        default = { };
      };

      corePlugins = mkOption {
        description = ''
          Core plugins to activate.

          Vault-specific settings take priority and will override these, if set.
        '';
        type = types.raw;
        default = [
          "backlink"
          "bookmarks"
          "canvas"
          "command-palette"
          "daily-notes"
          "editor-status"
          "file-explorer"
          "file-recovery"
          "global-search"
          "graph"
          "note-composer"
          "outgoing-link"
          "outline"
          "page-preview"
          "switcher"
          "tag-pane"
          "templates"
          "word-count"
        ];
      };

      communityPlugins = mkOption {
        description = "
          Community plugins to install and activate.

          Vault-specific settings take priority and will override these, if set.
        ";
        type = types.raw;
        default = [ ];
      };

      cssSnippets = mkOption {
        description = "
          CSS snippets to install.

          Vault-specific settings take priority and will override these, if set.
        ";
        type = types.raw;
        default = [ ];
      };

      themes = mkOption {
        description = "
          Themes to install.

          Vault-specific settings take priority and will override these, if set.
        ";
        type = types.raw;
        default = [ ];
      };

      hotkeys = mkOption {
        description = "
          Hotkeys to configure.

          Vault-specific settings take priority and will override these, if set.
        ";
        type = types.raw;
        default = { };
      };

      extraFiles = mkOption {
        description = "
          Extra files to link to the vault directory.

          Vault-specific settings take priority and will override these, if set.
        ";
        type = types.raw;
        default = { };
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
                  type = with types; attrsOf anything;
                  default = cfg.defaultSettings.app;
                };

                appearance = mkOption {
                  description = "Settings to write to appearance.json.";
                  type = with types; attrsOf anything;
                  default = cfg.defaultSettings.appearance;
                };

                corePlugins =
                  let
                    corePluginsOptions = {
                      options = {
                        enable = mkOption {
                          type = types.bool;
                          default = true;
                          description = "Whether to enable the plugin.";
                        };

                        name = mkOption {
                          type = types.enum corePlugins;
                          description = "The plugin.";
                        };

                        settings = mkOption {
                          type = with types; attrsOf anything;
                          description = "Plugin settings to include.";
                          default = { };
                        };
                      };
                    };
                  in
                  mkOption {
                    description = "Core plugins to activate.";
                    type =
                      with types;
                      listOf (coercedTo (enum corePlugins) (p: { name = p; }) (submodule corePluginsOptions));
                    default = cfg.defaultSettings.corePlugins;
                  };

                communityPlugins =
                  let
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
                          type = with types; attrsOf anything;
                          description = "Settings to include in the plugin's `data.json`.";
                          default = { };
                        };
                      };
                    };
                  in
                  mkOption {
                    description = "Community plugins to install and activate.";
                    type = with types; listOf (coercedTo package (p: { pkg = p; }) (submodule communityPluginsOptions));
                    default = cfg.defaultSettings.communityPlugins;
                  };

                cssSnippets =
                  let
                    checkCssPath = path: lib.filesystem.pathIsRegularFile path && lib.strings.hasSuffix ".css" path;
                    toCssName = path: lib.strings.removeSuffix ".css" (builtins.baseNameOf path);
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
                  in
                  mkOption {
                    description = "CSS snippets to install.";
                    type =
                      with types;
                      listOf (coercedTo (addCheck path checkCssPath) (p: { source = p; }) (submodule cssSnippetsOptions));
                    default = cfg.defaultSettings.cssSnippets;
                  };

                themes =
                  let
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
                  in
                  mkOption {
                    description = "Themes to install.";
                    type = with types; listOf (coercedTo package (p: { pkg = p; }) (submodule themesOptions));
                    default = cfg.defaultSettings.themes;
                  };

                hotkeys =
                  let
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
                  in
                  mkOption {
                    description = "Hotkeys to configure.";
                    type = with types; attrsOf (listOf (submodule hotkeysOptions));
                    default = cfg.defaultSettings.hotkeys;
                  };

                extraFiles =
                  let
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
                  in
                  mkOption {
                    description = "Extra files to link to the vault directory.";
                    type = with types; attrsOf (submodule extraFilesOptions);
                    default = cfg.defaultSettings.extraFiles;
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
        packages = [ cfg.package ];

        file =
          let
            mkApp = vault: {
              name = "${vault.target}/.obsidian/app.json";
              value.source = (pkgs.formats.json { }).generate "app.json" vault.settings.app;
            };

            mkAppearance = vault: {
              name = "${vault.target}/.obsidian/appearance.json";
              value =
                let
                  enabledCssSnippets = builtins.filter (snippet: snippet.enable) vault.settings.cssSnippets;
                  activeTheme = lib.lists.findSingle (
                    theme: theme.enable
                  ) null (throw "Only one theme can be enabled at a time.") vault.settings.themes;
                in
                {
                  source = (pkgs.formats.json { }).generate "appearance.json" (
                    vault.settings.appearance
                    // {
                      enabledCssSnippets = builtins.map (snippet: snippet.name) enabledCssSnippets;
                    }
                    // lib.attrsets.optionalAttrs (activeTheme != null) {
                      cssTheme = getManifest activeTheme;
                    }
                  );
                };
            };

            mkCorePlugins =
              vault:
              [
                {
                  name = "${vault.target}/.obsidian/core-plugins.json";
                  value.source = (pkgs.formats.json { }).generate "core-plugins.json" (
                    builtins.map (plugin: plugin.name) vault.settings.corePlugins
                  );
                }
                {
                  name = "${vault.target}/.obsidian/core-plugins-migration.json";
                  value.source = (pkgs.formats.json { }).generate "core-plugins-migration.json" (
                    builtins.listToAttrs (
                      builtins.map (name: {
                        inherit name;
                        value = builtins.any (plugin: name == plugin.name && plugin.enable) vault.settings.corePlugins;
                      }) corePlugins
                    )
                  );
                }
              ]
              ++ builtins.map (plugin: {
                name = "${vault.target}/.obsidian/${plugin.name}.json";
                value.source = (pkgs.formats.json { }).generate "${plugin.name}.json" plugin.settings;
              }) (builtins.filter (plugin: plugin.settings != { }) vault.settings.corePlugins);

            mkCommunityPlugins =
              vault:
              [
                {
                  name = "${vault.target}/.obsidian/community-plugins.json";
                  value.source = (pkgs.formats.json { }).generate "community-plugins.json" (
                    builtins.map getManifest (builtins.filter (plugin: plugin.enable) vault.settings.communityPlugins)
                  );
                }
              ]
              ++ builtins.map (plugin: {
                name = "${vault.target}/.obsidian/plugins/${getManifest plugin}";
                value = {
                  source = plugin.pkg;
                  recursive = true;
                };
              }) vault.settings.communityPlugins
              ++ builtins.map (plugin: {
                name = "${vault.target}/.obsidian/plugins/${getManifest plugin}/data.json";
                value.source = (pkgs.formats.json { }).generate "data.json" plugin.settings;
              }) (builtins.filter (plugin: plugin.settings != { }) vault.settings.communityPlugins);

            mkCssSnippets =
              vault:
              builtins.map (snippet: {
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
              }) vault.settings.cssSnippets;

            mkThemes =
              vault:
              builtins.map (theme: {
                name = "${vault.target}/.obsidian/themes/${getManifest theme}";
                value.source = theme.pkg;
              }) vault.settings.themes;

            mkHotkeys = vault: {
              name = "${vault.target}/.obsidian/hotkeys.json";
              value.source = (pkgs.formats.json { }).generate "hotkeys.json" vault.settings.hotkeys;
            };

            mkExtraFiles =
              vault:
              builtins.map (file: {
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
              }) (builtins.attrValues vault.settings.extraFiles);
          in
          builtins.listToAttrs (
            lib.lists.flatten (
              builtins.map (vault: [
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
      };

      xdg.configFile."obsidian/obsidian.json".source = (pkgs.formats.json { }).generate "obsidian.json" {
        vaults = builtins.listToAttrs (
          builtins.map (vault: {
            name = builtins.hashString "md5" vault.target;
            value = {
              path = "${config.home.homeDirectory}/${vault.target}";
            }
            // (lib.attrsets.optionalAttrs ((builtins.length vaults) == 1) {
              open = true;
            });
          }) vaults
        );
        updateDisabled = true;
      };

      assertions = [
        {
          assertion = builtins.all (
            vault:
            builtins.all (
              snippet:
              (snippet.source == null || snippet.text == null) && (snippet.source != null || snippet.text != null)
            ) vault.settings.cssSnippets
          ) (builtins.attrValues cfg.vaults);
          message = "Each CSS snippet must have one of 'source' or 'text' set";
        }
        {
          assertion = builtins.all (
            vault:
            builtins.all (
              file: (file.source == null || file.text == null) && (file.source != null || file.text != null)
            ) (builtins.attrValues vault.settings.extraFiles)
          ) (builtins.attrValues cfg.vaults);
          message = "Each extra file must have one of 'source' or 'text' set";
        }
      ];
    };

  meta.maintainers = [ lib.hm.maintainers.karaolidis ];
}
