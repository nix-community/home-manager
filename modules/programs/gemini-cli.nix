{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.gemini-cli;

  jsonFormat = pkgs.formats.json { };
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.maintainers.rrvsh ];

  options.programs.gemini-cli = {
    enable = lib.mkEnableOption "gemini-cli";

    package = lib.mkPackageOption pkgs "gemini-cli" { nullable = true; };

    enableMcpIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to integrate the MCP servers config from
        {option}`programs.mcp.servers` into
        {option}`programs.gemini-cli.settings.mcpServers`.

        Note: Settings defined in {option}`programs.mcp.servers` are merged
        with {option}`programs.gemini-cli.mcpServers`, with Gemini servers
        taking precedence.
      '';
    };

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        ui.theme = "Default";
        general = {
          vimMode = true;
          preferredEditor = "nvim";
          previewFeatures = true;
        };
        ide.enabled = true;
        privacy.usageStatisticsEnabled = false;
        tools.autoAccept = false;
        context.loadMemoryFromIncludeDirectories = true;
        security.auth.selectedType = "oauth-personal";
      };
      description = "JSON config for gemini-cli";
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
          An attribute set of custom commands that will be globally available.
          The name of the attribute set will be the name of each command.
          You may use subdirectories to create namespaced commands, such as `git/fix` becoming `/git:fix`.
          See https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/commands.md#custom-commands for more information.
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

    policies = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.path tomlFormat.type);
      default = { };
      description = ''
        An attribute set of policy definitions to create in `~/.gemini/policies/`.
        The attribute name becomes the filename with `.toml` extension automatically added.
        The value can be either an attribute set representing the TOML policy or a path to a TOML file.
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
        An attribute set of context files to create in `~/.gemini/`.
        The attribute name becomes the filename with `.md` extension automatically added.
        The value is either inline content or a path to a file.

        Note: You can customize which context file names gemini-cli looks for by setting
        `settings.context.fileName`. For example:
        ```nix
        settings = {
          context.fileName = ["AGENTS.md", "CONTEXT.md", "GEMINI.md"];
        };
        ```
      '';
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
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
        An attribute set of skill files to create in `~/.gemini/skills`.
        The attribute name becomes the directory name.
        The value is either inline content or a path to a file.
      '';
    };

    mcpServers = lib.mkOption {
      type = lib.types.attrsOf jsonFormat.type;
      default = { };
      description = "MCP (Model Context Protocol) servers configuration";
      example = {
        github = {
          url = "https://api.githubcopilot.com/mcp/";
        };
        filesystem = {
          command = "npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-filesystem"
            "/tmp"
          ];
        };
        database = {
          command = "npx";
          args = [
            "-y"
            "@bytebase/dbhub"
            "--dsn"
            "postgresql://user:pass@localhost:5432/db"
          ];
          env = {
            DATABASE_URL = "postgresql://user:pass@localhost:5432/db";
          };
        };
        customTransport = {
          url = "wss://example.com/mcp";
          customOption = "value";
          timeout = 5000;
          trust = true;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs.gemini-cli.settings.mcpServers = lib.mkIf (cfg.mcpServers != { }) cfg.mcpServers;
      }
      {
        programs.gemini-cli.settings.mcpServers = lib.mkIf (
          cfg.enableMcpIntegration && config.programs.mcp.enable && config.programs.mcp.servers
        ) config.programs.mcp.servers;
      }
      {
        home = {
          packages = lib.mkIf (cfg.package != null) [ cfg.package ];
          file.".gemini/settings.json" = lib.mkIf (cfg.settings != { }) {
            source = jsonFormat.generate "gemini-cli-settings.json" cfg.settings;
          };
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
      {
        home.file = lib.mapAttrs' (
          n: v:
          lib.nameValuePair ".gemini/commands/${n}.toml" {
            source = tomlFormat.generate "gemini-cli-command-${n}.toml" {
              inherit (v) description prompt;
            };
          }
        ) cfg.commands;
      }
      {
        home.file = lib.mapAttrs' (
          n: v:
          lib.nameValuePair ".gemini/policies/${n}.toml" {
            source =
              if builtins.isPath v || builtins.isString v || lib.isDerivation v then
                v
              else
                tomlFormat.generate "gemini-cli-policy-${n}.toml" v;
          }
        ) cfg.policies;
      }
      {
        home.file = lib.mapAttrs' (
          n: v:
          if lib.isPath v && lib.pathIsDirectory v then
            lib.nameValuePair ".gemini/skills/${n}" {
              source = v;
              recursive = true;
            }
          else
            lib.nameValuePair ".gemini/skills/${n}/SKILL.md" (
              if lib.isPath v then { source = v; } else { text = v; }
            )
        ) cfg.skills;
      }
    ]
  );
}
