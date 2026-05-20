{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.antigravity-cli;

  jsonFormat = pkgs.formats.json { };
  tomlFormat = pkgs.formats.toml { };

  isStorePathString =
    content: builtins.isString content && lib.hasPrefix "${builtins.storeDir}/" content;

  isPathLikeContent = content: lib.isPath content || isStorePathString content;

  transformMcpServer =
    server:
    removeAttrs server [
      "httpUrl"
      "url"
    ]
    // lib.optionalAttrs (server ? httpUrl) {
      serverUrl = server.httpUrl;
    }
    // lib.optionalAttrs (server ? url) {
      serverUrl = server.url;
    };

  transformMcpServers = lib.mapAttrs (_name: transformMcpServer);

  commandSkillName = lib.replaceStrings [ "/" ] [ ":" ];

in
{
  meta.maintainers = [ lib.maintainers.rrvsh ];

  imports = [
    (lib.mkRenamedOptionModule [ "programs" "gemini-cli" ] [ "programs" "antigravity-cli" ])
  ];

  options.programs.antigravity-cli = {
    enable = lib.mkEnableOption "Antigravity CLI";

    package = lib.mkPackageOption pkgs "antigravity-cli" {
      nullable = true;
    };

    useLegacyGeminiConfig = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to write configuration to the legacy Gemini CLI locations.

        This is enabled automatically when
        {option}`programs.antigravity-cli.package` is a `gemini-cli` package.
      '';
    };

    enableMcpIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to integrate the MCP servers config from
        {option}`programs.mcp.servers` into
        {option}`programs.antigravity-cli.mcpServers`.

        Note: Any servers already present in
        {option}`programs.antigravity-cli.mcpServers`
        is not overridden by servers present under the same
        name in {option}`programs.mcp.servers`
      '';
    };

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        colorScheme = "tokyo night";
        altScreenMode = "always";
        toolPermission = "proceed-in-sandbox";
        artifactReviewPolicy = "agent-decides";
      };
      description = ''
        Configuration written to
        {file}`~/.gemini/antigravity-cli/settings.json`.
      '';
    };

    mcpServers = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        github = {
          serverUrl = "https://api.githubcopilot.com/mcp/";
        };
        filesystem = {
          command = "npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-filesystem"
            "/tmp"
          ];
        };
      };
      description = ''
        MCP server configuration written to
        {file}`~/.gemini/config/mcp_config.json`.

        Remote servers use `serverUrl`; `url` and `httpUrl` are accepted
        for migration and converted automatically.
      '';
    };

    commands =
      let
        commandType = lib.types.submodule {
          freeformType = lib.types.str;
          options = {
            prompt = lib.mkOption {
              type = lib.types.str;
              description = ''
                The prompt that will be sent to the Gemini model when the command is executed.
                This can be a single-line or multi-line string.
                The special placeholder {{args}} will be replaced with the text the user typed after the command name.
              '';
            };
            description = lib.mkOption {
              type = lib.types.str;
              description = ''
                A brief, one-line description of what the command does.
                This text will be displayed next to your command in the /help menu.
                If you omit this field, a generic description will be generated from the filename.
              '';
            };
          };
        };
      in
      lib.mkOption {
        type = lib.types.attrsOf commandType;
        default = { };
        description = ''
          An attribute set of Gemini CLI custom commands to migrate to
          Antigravity CLI global skills.

          The name of the attribute set will be the name of each generated
          skill directory.
        '';
        example = lib.literalExpression ''
          changelog = {
            prompt =
              '''
              Your task is to parse the `<version>`, `<change_type>`, and `<message>` from their input and use the `write_file` tool to correctly update the `CHANGELOG.md` file.
              ''';
            description = "Adds a new entry to the project's CHANGELOG.md file.";
          };
          "git/fix" = { # Becomes /git:fix
            prompt = "Please analyze the staged git changes and provide a code fix for the issue described here: {{args}}.";
            description = "Generates a fix for a given GitHub issue.";
          };
        '';
      };

    permissions = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            allow = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = ''
                Permissions to allow without prompting.
              '';
            };

            deny = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = ''
                Permissions to deny without prompting.
              '';
            };

            ask = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = ''
                Permissions to ask before using.
              '';
            };
          };
        }
      );
      default = null;
      description = ''
        Antigravity CLI fine-grained permissions written to
        {option}`programs.antigravity-cli.settings.permissions`.
      '';
      example = lib.literalExpression ''
        {
          allow = [ "command(git)" ];
          deny = [ "command(rm -rf)" ];
          ask = [ "command(*)" ];
        }
      '';
    };

    policies = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.path tomlFormat.type);
      default = { };
      description = ''
        An attribute set of Gemini CLI policy definitions to create in
        {file}`~/.gemini/policies/` when
        {option}`programs.antigravity-cli.package` is a `gemini-cli`
        package.

        Antigravity CLI configures permissions in
        {option}`programs.antigravity-cli.settings.permissions` or
        {option}`programs.antigravity-cli.permissions`.
      '';
      example = lib.literalExpression ''
        {
          "my-rules" = {
            rule = [
              {
                toolName = "run_shell_command";
                commandPrefix = "git ";
                decision = "ask_user";
                priority = 100;
              }
            ];
          };
          "other-rules" = ./path/to/rules.toml;
        }
      '';
    };

    defaultModel = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "gemini-2.5-flash";
      description = ''
        The default model to use for the CLI.
        Will be set as $GEMINI_MODEL when configured.
      '';
    };

    context = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
      default = { };
      example = lib.literalExpression ''
        {
          GEMINI = '''
            # Global Context

            You are a helpful AI assistant for software development.

            ## Coding Standards

            - Follow consistent code style
            - Write clear comments
            - Test your changes
          ''';

          AGENTS = ./path/to/agents.md;

          CONTEXT = '''
            Additional context instructions here.
          ''';
        }
      '';
      description = ''
        Global context(s) for Antigravity CLI.

        The attribute name becomes the filename, with a {file}`.md`
        extension added automatically. Each value is either:
        - Inline content as a string
        - A path to a file containing the content

        The configured files are written to {file}`~/.gemini/`.

        Note: You can customize which context file names Antigravity CLI looks for by setting
        `settings.context.fileName`. For example:
        ```nix
        settings = {
          context.fileName = ["AGENTS.md", "CONTEXT.md", "GEMINI.md"];
        };
        ```
      '';
    };

    skills = lib.mkOption {
      type = lib.types.either (lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path)) lib.types.path;
      default = { };
      example = lib.literalExpression ''
        {
          xlsx = ./skills/xlsx/SKILL.md;
          data-analysis = ./skills/data-analysis;
          pdf-processing = '''
            ---
            name: pdf-processing
            description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
            ---

            # PDF Processing

            ## Quick start

            Use pdfplumber to extract text from PDFs:

            ```python
            import pdfplumber

            with pdfplumber.open("document.pdf") as pdf:
                text = pdf.pages[0].extract_text()
            ```
          ''';
        }
      '';
      description = ''
        Custom skills for Antigravity CLI.

        This option can be either:
        - An attribute set defining skills
        - A path to a directory containing skill folders

        If an attribute set is used, the attribute name becomes the
        skill directory name, and the value is either:
        - Inline content as a string (creates `~/.gemini/config/skills/<name>/SKILL.md`)
        - A path to a file (creates `~/.gemini/config/skills/<name>/SKILL.md`)
        - A path to a directory (symlinks `~/.gemini/config/skills/<name>/` to that directory)

        If a path is used, it is expected to contain one folder per
        skill name, each containing a {file}`SKILL.md`. The directory is
        symlinked to {file}`~/.gemini/config/skills/`.
      '';
    };
  };

  config =
    let
      useGeminiConfig =
        cfg.useLegacyGeminiConfig || (cfg.package != null && lib.getName cfg.package == "gemini-cli");
      antigravitySkillsDir = ".gemini/config/skills";
      geminiSkillsDir = ".gemini/skills";
      antigravitySettings = lib.recursiveUpdate (lib.optionalAttrs (cfg.permissions != null) {
        inherit (cfg) permissions;
      }) (removeAttrs cfg.settings [ "mcpServers" ]);
      legacyMcpServers = lib.optionalAttrs (cfg.settings ? mcpServers) cfg.settings.mcpServers;
      mcpServers = lib.recursiveUpdate legacyMcpServers cfg.mcpServers;
      geminiSettings =
        lib.recursiveUpdate
          (lib.optionalAttrs (cfg.permissions != null) {
            inherit (cfg) permissions;
          })
          (lib.recursiveUpdate cfg.settings (lib.optionalAttrs (mcpServers != { }) { inherit mcpServers; }));
    in
    lib.mkIf cfg.enable (
      lib.mkMerge [
        {
          home = {
            packages = lib.mkIf (cfg.package != null) [ cfg.package ];
            sessionVariables = lib.mkIf (cfg.defaultModel != null) {
              GEMINI_MODEL = cfg.defaultModel;
            };
          };
        }
        {
          home.file = lib.mapAttrs' (
            n: v: lib.nameValuePair ".gemini/${n}.md" (if lib.isPath v then { source = v; } else { text = v; })
          ) cfg.context;
        }
        (lib.mkIf useGeminiConfig {
          programs.antigravity-cli.settings.mcpServers = lib.mkIf (
            cfg.enableMcpIntegration && config.programs.mcp.enable
          ) (lib.mapAttrs (_n: lib.mkDefault) config.programs.mcp.servers);

          home.file =
            lib.optionalAttrs (geminiSettings != { }) {
              ".gemini/settings.json".source = jsonFormat.generate "gemini-cli-settings.json" geminiSettings;
            }
            // lib.mapAttrs' (
              n: v:
              lib.nameValuePair ".gemini/commands/${n}.toml" {
                source = tomlFormat.generate "gemini-cli-command-${n}.toml" {
                  inherit (v) description prompt;
                };
              }
            ) cfg.commands
            // lib.mapAttrs' (
              n: v:
              lib.nameValuePair ".gemini/policies/${n}.toml" {
                source =
                  if isPathLikeContent v then v else tomlFormat.generate "gemini-cli-policy-${n}.toml" v;
              }
            ) cfg.policies
            // (
              if isPathLikeContent cfg.skills then
                {
                  "${geminiSkillsDir}" = {
                    source = cfg.skills;
                    recursive = true;
                  };
                }
              else
                lib.mapAttrs' (
                  n: v:
                  if isPathLikeContent v && lib.pathIsDirectory v then
                    lib.nameValuePair "${geminiSkillsDir}/${n}" {
                      source = v;
                      recursive = true;
                    }
                  else
                    lib.nameValuePair "${geminiSkillsDir}/${n}/SKILL.md" (
                      if isPathLikeContent v then { source = v; } else { text = v; }
                    )
                ) cfg.skills
            );
        })
        (lib.mkIf (!useGeminiConfig) {
          programs.antigravity-cli.mcpServers =
            lib.mkIf (cfg.enableMcpIntegration && config.programs.mcp.enable)
              (lib.mapAttrs (_n: server: lib.mkDefault (transformMcpServer server)) config.programs.mcp.servers);

          assertions = [
            {
              assertion = cfg.policies == { };
              message = ''
                `programs.antigravity-cli.policies` is only supported when
                `programs.antigravity-cli.package` is a `gemini-cli` package.
                Antigravity CLI configures permissions in
                `programs.antigravity-cli.settings.permissions` or
                `programs.antigravity-cli.permissions`.
              '';
            }
          ];

          home.file =
            lib.optionalAttrs (antigravitySettings != { }) {
              ".gemini/antigravity-cli/settings.json".source =
                jsonFormat.generate "antigravity-cli-settings.json" antigravitySettings;
            }
            // lib.optionalAttrs (mcpServers != { }) {
              ".gemini/config/mcp_config.json".source = jsonFormat.generate "antigravity-cli-mcp-config.json" {
                mcpServers = transformMcpServers mcpServers;
              };
            }
            // lib.mapAttrs' (
              n: v:
              let
                skillName = commandSkillName n;
              in
              lib.nameValuePair "${antigravitySkillsDir}/${skillName}/SKILL.md" {
                text = ''
                  ---
                  name: ${skillName}
                  description: ${v.description}
                  ---

                  ${v.prompt}
                '';
              }
            ) cfg.commands
            // (
              if isPathLikeContent cfg.skills then
                {
                  "${antigravitySkillsDir}" = {
                    source = cfg.skills;
                    recursive = true;
                  };
                }
              else
                lib.mapAttrs' (
                  n: v:
                  if isPathLikeContent v && lib.pathIsDirectory v then
                    lib.nameValuePair "${antigravitySkillsDir}/${n}" {
                      source = v;
                      recursive = true;
                    }
                  else
                    lib.nameValuePair "${antigravitySkillsDir}/${n}/SKILL.md" (
                      if isPathLikeContent v then { source = v; } else { text = v; }
                    )
                ) cfg.skills
            );
        })
        {
          assertions = [
            {
              assertion = !isPathLikeContent cfg.skills || lib.pathIsDirectory cfg.skills;
              message = "`programs.antigravity-cli.skills` must be a directory when set to a path";
            }
          ];
        }
      ]
    );
}
