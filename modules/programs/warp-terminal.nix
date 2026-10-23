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
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.warp-terminal;

  tomlFormat = pkgs.formats.toml { };
  yamlFormat = pkgs.formats.yaml { };
  jsonFormat = pkgs.formats.json { };

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  homeDir = config.home.homeDirectory;
  configDir = if isDarwin then "${homeDir}/.warp" else "${config.xdg.configHome}/warp-terminal";
  dataDir = if isDarwin then "${homeDir}/.warp" else "${config.xdg.dataHome}/warp-terminal";
  agentDir = "${homeDir}/.warp";

  settingsSchema =
    if isDarwin then
      "${cfg.package}/Applications/Warp.app/Contents/Resources/settings_schema.json"
    else
      "${cfg.package}/opt/warpdotdev/warp-terminal/resources/settings_schema.json";

  generatedSettings = tomlFormat.generate "warp-terminal-settings.toml" cfg.settings;

  validatedSettings =
    pkgs.runCommandLocal "warp-terminal-settings.toml"
      { nativeBuildInputs = [ pkgs.check-jsonschema ]; }
      ''
        check-jsonschema --schemafile ${settingsSchema} ${generatedSettings}
        cp ${generatedSettings} $out
      '';

  documentType = format: types.attrsOf (types.either types.path format.type);

  mkDocumentFiles =
    format: dir: extension:
    lib.mapAttrs' (
      name: document:
      lib.nameValuePair "${dir}/${name}.${extension}" {
        source =
          if types.path.check document then
            document
          else
            format.generate "warp-terminal-${name}.${extension}" document;
      }
    );

  mkSkillFile =
    name: skill:
    if types.path.check skill then
      lib.nameValuePair "${agentDir}/skills/${name}" { source = skill; }
    else
      lib.nameValuePair "${agentDir}/skills/${name}/SKILL.md" { text = skill; };

  isServerEnabled = server: lib.hm.mcp.resolveEnabled server != false;

  sharedMcpServers = lib.mapAttrs (
    name: server:
    lib.hm.mcp.transformMcpServer {
      inherit server;
      exclude = [ "enabled" ];
      extraTransforms = [ (lib.hm.mcp.wrapEnvFilesCommand { inherit pkgs name; }) ];
    }
  ) (lib.filterAttrs (_: isServerEnabled) config.programs.mcp.servers);

  mcpServers =
    lib.optionalAttrs (cfg.enableMcpIntegration && config.programs.mcp.enable) sharedMcpServers
    // cfg.mcpServers;
in
{
  meta.maintainers = [ lib.hm.maintainers.kimhappy ];

  options.programs.warp-terminal = {
    enable = mkEnableOption "Warp, the agentic development environment born out of the terminal";

    package = lib.mkPackageOption pkgs "warp-terminal" {
      nullable = true;
      extraDescription = ''
        Set to `null` to manage only the configuration, for example when Warp
        is installed with Homebrew on macOS.

        To run Warp natively on Wayland, override the package:
        `pkgs.warp-terminal.override { waylandSupport = true; }`.
      '';
    };

    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      example = literalExpression ''
        {
          appearance = {
            text = {
              font_name = "JetBrains Mono";
              font_size = 14.0;
              line_height_ratio = 1.3;
              ligature_rendering_enabled = true;
            };
            themes.theme = "dracula";
          };
          terminal.input = {
            syntax_highlighting = true;
            honor_ps1 = false;
          };
          text_editing = {
            vim_mode_enabled = true;
            vim_status_bar = true;
          };
          agents.profiles = {
            agent_mode_execute_readonly_commands = true;
            agent_mode_command_execution_allowlist = [
              "ls(\\s.*)?"
              "cat(\\s.*)?"
            ];
          };
        }
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/warp-terminal/settings.toml`
        on Linux and {file}`~/.warp/settings.toml` on macOS.

        The file is read-only once managed, so changes made in the Warp
        Settings panel are not persisted.

        To select a theme defined in {option}`programs.warp-terminal.themes`,
        set `appearance.themes.theme.custom` to its `name` and the `path` of
        its file, for example
        `"''${config.xdg.dataHome}/warp-terminal/themes/solarized_nix.yaml"` on Linux.

        See <https://docs.warp.dev/terminal/settings/all-settings/> for the
        available settings.
      '';
    };

    validateSettings = mkOption {
      type = types.bool;
      default = cfg.package != null;
      defaultText = literalExpression "config.programs.warp-terminal.package != null";
      example = false;
      description = ''
        Whether to validate {option}`programs.warp-terminal.settings` at build
        time against the JSON schema bundled with
        {option}`programs.warp-terminal.package`.

        Validation catches wrong value types and unknown enum values, such as
        `font_weight = "heavy"`. It does not reject unknown keys.
      '';
    };

    keybindings = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        "workspace:toggle_warp_drive" = "ctrl-shift-D";
        "pane_group:add_right" = "ctrl-shift-E";
        "terminal:clear_blocks" = "ctrl-L";
      };
      description = ''
        Keyboard shortcuts written to {file}`$XDG_CONFIG_HOME/warp-terminal/keybindings.yaml`
        on Linux and {file}`~/.warp/keybindings.yaml` on macOS.

        The file is read-only once managed, so shortcuts changed in the Warp
        Settings panel are not persisted.

        Each attribute maps an action name to a hyphen-separated list of
        modifiers ending with the key. The available modifiers are `ctrl`,
        `alt`, `meta`, `shift`, `cmd` on macOS, and `cmdorctrl`, which is `cmd`
        on macOS and `ctrl` elsewhere. A printable key must reflect the `shift`
        modifier, so `Ctrl+Shift+A` is `ctrl-shift-A`. Separate the keystrokes
        of a sequence with spaces, and use `none` to remove a default shortcut.

        See <https://docs.warp.dev/getting-started/keyboard-shortcuts/> for the
        action names and <https://github.com/warpdotdev/keysets> for the format.
      '';
    };

    themes = mkOption {
      type = documentType yamlFormat;
      default = { };
      example = literalExpression ''
        {
          solarized_nix = {
            name = "Solarized Nix";
            accent = "#268bd2";
            cursor = "#95D886";
            background = "#002b36";
            foreground = "#839496";
            details = "darker";
            terminal_colors = {
              normal = {
                black = "#073642";
                red = "#dc322f";
                green = "#859900";
                yellow = "#b58900";
                blue = "#268bd2";
                magenta = "#d33682";
                cyan = "#2aa198";
                white = "#eee8d5";
              };
              bright = {
                black = "#002b36";
                red = "#cb4b16";
                green = "#586e75";
                yellow = "#657b83";
                blue = "#839496";
                magenta = "#6c71c4";
                cyan = "#93a1a1";
                white = "#fdf6e3";
              };
            };
          };
          dracula = ./themes/dracula.yaml;
        }
      '';
      description = ''
        Custom themes written to {file}`$XDG_DATA_HOME/warp-terminal/themes/<name>.yaml`
        on Linux and {file}`~/.warp/themes/<name>.yaml` on macOS.

        Each value is either a theme definition or a path to an existing
        theme file. The theme picker shows the `name` field of the theme, or a
        name derived from the attribute name when `name` is unset.

        See <https://docs.warp.dev/terminal/appearance/custom-themes/> for the
        format and <https://github.com/warpdotdev/themes> for ready-made themes.
      '';
    };

    tabConfigs = mkOption {
      type = documentType tomlFormat;
      default = { };
      example = literalExpression ''
        {
          editor_server = {
            name = "Editor + Server";
            color = "green";
            panes = [
              {
                id = "root";
                split = "horizontal";
                children = [ "editor" "server" ];
              }
              {
                id = "editor";
                type = "terminal";
                directory = "~/code/my-app";
                commands = [ "nvim ." ];
                is_focused = true;
              }
              {
                id = "server";
                type = "terminal";
                directory = "~/code/my-app";
                commands = [ "npm run dev" ];
              }
            ];
          };
          new_worktree = {
            name = "New Worktree";
            title = "{{branch_name}}";
            panes = [
              {
                id = "main";
                type = "terminal";
                directory = "{{repo}}";
                commands = [ "git worktree add -b {{branch_name}} ../{{branch_name}} {{base_branch}}" ];
              }
            ];
            params = {
              repo.type = "repo";
              base_branch.type = "branch";
              branch_name = {
                type = "text";
                default = "my-feature";
              };
            };
          };
        }
      '';
      description = ''
        Tab Configs written to {file}`$XDG_DATA_HOME/warp-terminal/tab_configs/<name>.toml`
        on Linux and {file}`~/.warp/tab_configs/<name>.toml` on macOS.

        Each value is either a Tab Config or a path to an existing Tab Config
        file. The attribute name is the file stem used by
        `warp://tab_config/<name>`.

        See <https://docs.warp.dev/terminal/windows/tab-configs/> for the schema.
      '';
    };

    defaultTabConfigs = mkOption {
      type = documentType tomlFormat;
      default = { };
      example = literalExpression ''
        {
          worktree = {
            name = "Worktree";
            panes = [
              {
                id = "main";
                type = "{{pane_type}}";
                directory = "{{repo}}";
                commands = [
                  "git worktree add -b {{autogenerated_branch_name}} \"{{worktree_path_prefix}}{{autogenerated_branch_name}}\""
                  "cd \"{{worktree_path_prefix}}{{autogenerated_branch_name}}\""
                  "nvim ."
                ];
              }
            ];
            params = {
              repo.type = "repo";
              pane_type = {
                type = "text";
                default = "terminal";
              };
            };
          };
        }
      '';
      description = ''
        Default Tab Configs written to
        {file}`$XDG_DATA_HOME/warp-terminal/default_tab_configs/<name>.toml`
        on Linux and {file}`~/.warp/default_tab_configs/<name>.toml` on macOS.

        Each value is either a Tab Config or a path to an existing Tab Config
        file. Warp creates `worktree` from a built-in template when it is
        missing and uses it for new worktrees, so defining `worktree` replaces
        that template.

        See <https://docs.warp.dev/terminal/windows/tab-configs/> for the schema.
      '';
    };

    workflows = mkOption {
      type = documentType yamlFormat;
      default = { };
      example = literalExpression ''
        {
          git_undo = {
            name = "Undo the last commit";
            command = "git reset --soft HEAD~{{count}}";
            tags = [ "git" ];
            description = "Undo commits while keeping the changes staged.";
            arguments = [
              {
                name = "count";
                description = "Number of commits to undo";
                default_value = "1";
              }
            ];
          };
        }
      '';
      description = ''
        YAML Workflows written to {file}`$XDG_DATA_HOME/warp-terminal/workflows/<name>.yaml`
        on Linux and {file}`~/.warp/workflows/<name>.yaml` on macOS.

        Each value is either a workflow or a path to an existing workflow file.

        See <https://docs.warp.dev/terminal/entry/yaml-workflows/> for the format.
      '';
    };

    launchConfigurations = mkOption {
      type = documentType yamlFormat;
      default = { };
      example = literalExpression ''
        {
          example_tabs = {
            name = "Example Tabs";
            windows = [
              {
                tabs = [
                  {
                    title = "Documents";
                    layout.cwd = "''${config.home.homeDirectory}/Documents";
                    color = "blue";
                  }
                  {
                    title = "Home";
                    layout.cwd = config.home.homeDirectory;
                    color = "green";
                  }
                ];
              }
            ];
          };
        }
      '';
      description = ''
        Launch Configurations written to
        {file}`$XDG_DATA_HOME/warp-terminal/launch_configurations/<name>.yaml`
        on Linux and {file}`~/.warp/launch_configurations/<name>.yaml` on macOS.

        Launch Configurations are a legacy feature superseded by
        {option}`programs.warp-terminal.tabConfigs`. Every `cwd` must be an
        absolute path or `""`.

        See <https://docs.warp.dev/terminal/sessions/launch-configurations/> for
        the format.
      '';
    };

    customModelRouters = mkOption {
      type = documentType yamlFormat;
      default = { };
      example = literalExpression ''
        {
          cost_saver = {
            name = "Cost saver";
            type = "complexity";
            default = "glm-5.3-fireworks";
            routing = {
              easy = "minimax-3-fireworks";
              hard = "deepseek-v4.1-flash-fireworks";
            };
          };
          by_task = {
            name = "By task";
            type = "prompt";
            default = "claude-4-6-sonnet-high";
            routing = [
              {
                description = "debugging production incidents or fixing failing CI tests";
                model = "claude-4-8-opus-high";
              }
            ];
          };
        }
      '';
      description = ''
        Custom model routers written to
        {file}`$XDG_DATA_HOME/warp-terminal/custom_model_routers/<name>.yaml`
        on Linux and {file}`~/.warp/custom_model_routers/<name>.yaml` on macOS.

        Each value is either a router or a path to an existing router file.
        The files are read-only once managed, so changes made to these routers
        in the Warp Settings panel are not persisted.

        See <https://docs.warp.dev/agents/inference/custom-routers/> for the
        format and <https://docs.warp.dev/agents/inference/model-choice/> for
        the model IDs.
      '';
    };

    enableMcpIntegration = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Whether to include the servers of {option}`programs.mcp.servers` in
        {file}`~/.warp/.mcp.json`. Disabled servers are left out, and servers
        with file-backed environment variables are wrapped in a script that
        reads them at startup.

        {option}`programs.warp-terminal.mcpServers` takes precedence on name
        conflicts.
      '';
    };

    mcpServers = mkOption {
      type = types.attrsOf jsonFormat.type;
      default = { };
      example = literalExpression ''
        {
          filesystem = {
            command = "npx";
            args = [ "-y" "@modelcontextprotocol/server-filesystem" "/path/to/allowed/files" ];
          };
          externalDocs = {
            url = "http://localhost:4000/mcp/stream";
            headers.my-header = "my-header-value";
          };
        }
      '';
      description = ''
        MCP servers written under `mcpServers` in {file}`~/.warp/.mcp.json`.
        Warp spawns these global servers automatically.

        A local server sets `command`, `args`, and `env`. A remote server sets
        `url` and `headers`.

        See <https://docs.warp.dev/agents/capabilities/mcp/> for the format.
      '';
    };

    skills = mkOption {
      type = types.attrsOf (types.either types.path types.lines);
      default = { };
      example = literalExpression ''
        {
          git-workflow = '''
            ---
            name: git-workflow
            description: Create atomic commits with lowercase imperative messages.
            ---

            Stage related changes together and commit each logical change separately.
          ''';
          code-review = ./skills/code-review;
        }
      '';
      description = ''
        Global agent skills written to {file}`~/.warp/skills/<name>`.

        Each value is either the content of {file}`SKILL.md` or a path to a
        directory that contains {file}`SKILL.md` and its supporting files.

        See <https://docs.warp.dev/agents/capabilities/skills/> for the format.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.validateSettings -> cfg.package != null;
        message = "programs.warp-terminal.validateSettings requires programs.warp-terminal.package to provide the settings schema.";
      }
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    home.file = lib.mkMerge [
      (mkIf (cfg.settings != { }) {
        "${configDir}/settings.toml".source =
          if cfg.validateSettings then validatedSettings else generatedSettings;
      })
      (mkIf (cfg.keybindings != { }) {
        "${configDir}/keybindings.yaml".source =
          yamlFormat.generate "warp-terminal-keybindings.yaml" cfg.keybindings;
      })
      (mkDocumentFiles yamlFormat "${dataDir}/themes" "yaml" cfg.themes)
      (mkDocumentFiles tomlFormat "${dataDir}/tab_configs" "toml" cfg.tabConfigs)
      (mkDocumentFiles tomlFormat "${dataDir}/default_tab_configs" "toml" cfg.defaultTabConfigs)
      (mkDocumentFiles yamlFormat "${dataDir}/workflows" "yaml" cfg.workflows)
      (mkDocumentFiles yamlFormat "${dataDir}/launch_configurations" "yaml" cfg.launchConfigurations)
      (mkDocumentFiles yamlFormat "${dataDir}/custom_model_routers" "yaml" cfg.customModelRouters)
      (mkIf (mcpServers != { }) {
        "${agentDir}/.mcp.json".source = jsonFormat.generate "warp-terminal-mcp.json" {
          inherit mcpServers;
        };
      })
      (lib.mapAttrs' mkSkillFile cfg.skills)
    ];
  };
}
