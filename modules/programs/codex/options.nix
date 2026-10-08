{ lib, pkgs, ... }:
let
  tomlFormat = pkgs.formats.toml { };
  jsonFormat = pkgs.formats.json { };
in
{
  options.programs.codex = {
    enable = lib.mkEnableOption "Lightweight coding agent that runs in your terminal";

    package = lib.mkPackageOption pkgs "codex" { nullable = true; };

    enableMcpIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to integrate the MCP server config from
        {option}`programs.mcp.servers` into
        {option}`programs.codex.settings.mcp_servers`.

        Note: Settings defined in {option}`programs.mcp.servers` are merged
        with {option}`programs.codex.settings.mcp_servers`, with settings-based
        values taking precedence.
      '';
    };

    settings = lib.mkOption {
      # NOTE: `yaml` type supports null, using `nullOr` for backwards compatibility period
      type = lib.types.nullOr tomlFormat.type;
      description = ''
        Configuration written to {file}`CODEX_HOME/config.toml` (0.2.0+)
        or {file}`~/.codex/config.yaml` (<0.2.0). Per default {env}`CODEX_HOME`
        defaults to ~/.codex.
        See <https://developers.openai.com/codex/config-reference> for supported values.
      '';
      default = { };
      defaultText = lib.literalExpression "{ }";
      example = lib.literalExpression ''
        {
          model = "gemma3:latest";
          model_provider = "ollama";
          model_providers = {
            ollama = {
              name = "Ollama";
              base_url = "http://localhost:11434/v1";
              env_key = "OLLAMA_API_KEY";
            };
          };
          mcp_servers = {
            context7 = {
              command = "npx";
              args = [
                "-y"
                "@upstash/context7-mcp"
              ];
            };
          };
        }
      '';
    };

    profiles = lib.mkOption {
      type = lib.types.attrsOf tomlFormat.type;
      default = { };
      description = ''
        Named Codex configuration profiles written to
        {file}`CODEX_HOME/<name>.config.toml`.

        These profiles are selected with {command}`codex --profile <name>`.
        Codex 0.134.0 and later no longer reads profile settings from
        {option}`programs.codex.settings.profiles`, and the top-level
        {option}`programs.codex.settings.profile` selector is no longer
        supported.
      '';
      example = lib.literalExpression ''
        {
          deep-review = {
            model = "gpt-5.5";
            model_reasoning_effort = "xhigh";
            approval_policy = "on-request";
            sandbox_mode = "workspace-write";
          };
        }
      '';
    };

    context = lib.mkOption {
      type = lib.types.either lib.types.lines lib.types.path;
      description = ''
        Global context for Codex.

        The value is either:
        - Inline content as a string
        - A path to a file containing the content

        The configured content is written to
        {file}`CODEX_HOME/AGENTS.md`.
      '';
      default = "";
      example = lib.literalExpression ''
        '''
          - Always respond with emojis
          - Only use git commands when explicitly requested
        '''
      '';
    };

    contextOverride = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.lines lib.types.path);
      description = ''
        Global override context for Codex.

        This has the same value format as {option}`programs.codex.context`,
        but writes {file}`CODEX_HOME/AGENTS.override.md`.

        Codex prefers {file}`AGENTS.override.md` over
        {file}`AGENTS.md` in the same directory.
      '';
      default = null;
      example = lib.literalExpression ''
        '''
          - Temporarily ignore default global guidance
          - Prefer brief answers while debugging
        '''
      '';
    };

    hooks = lib.mkOption {
      type = lib.types.either jsonFormat.type lib.types.path;
      default = { };
      description = ''
        Lifecycle hook events written to {file}`CODEX_HOME/hooks.json`.

        This option can either be a hook event attribute set, a path to a
        complete hooks JSON file, or a path to a hook bundle directory
        containing {file}`hooks.json` and supporting hook scripts.

        Attribute set values use the same event structure as
        {option}`programs.codex.settings.hooks` and are written under the
        top-level `hooks` key expected by Codex's JSON hooks file.

        Directory values install {file}`hooks.json` to
        {file}`CODEX_HOME/hooks.json` and install the full directory to
        the active Codex home hooks directory. In the default layout, commands
        can reference bundled scripts with paths such as
        {file}`$HOME/.codex/hooks/my-hook`. When
        {option}`home.preferXdgDirectories` is enabled, use
        {file}`$CODEX_HOME/hooks/my-hook`.

        Hooks can also be configured inline through
        {option}`programs.codex.settings.hooks`; prefer using only one hook
        representation per layer.
      '';
      example = lib.literalExpression ''
        {
          PreToolUse = [
            {
              matcher = "^Bash$";
              hooks = [
                {
                  type = "command";
                  command = "/usr/local/bin/codex-pre-tool-use";
                  timeout = 30;
                  statusMessage = "Checking Bash command";
                }
              ];
            }
          ];
        }
      '';
    };

    plugins = lib.mkOption {
      type = with lib.types; listOf (either package path);
      default = [ ];
      description = ''
        List of plugins to use when running Codex.
        Each entry is either:
        - A path to the plugin directory
        - The plugin package, whether a nix package or the output of a fetcher
        Plugins are installed into Codex's plugin cache and enabled through
        {file}`CODEX_HOME/config.toml`.

        Warning: If using a derivation as the source for a plugin, make sure that
        the derivation name matches the name of the plugin in the manifest file.
      '';
      example = lib.literalExpression ''
        [
          ./my-local-plugin
          (fetchFromGitHub {
            owner = "some-github-org";
            repo = "codex-plugin";
            rev = "779a68ebc2a75e4a184d2c87e5a43a758e6458a1";
            sha256 = "228fdd7e5908ea1d2f65218ecd9c71e1eefa0834d200d55fbb8bf8b5563acec0";
          })
        ]
      '';
    };

    marketplaces = lib.mkOption {
      type = with lib.types; attrsOf (either package path);
      default = { };
      description = ''
        Custom marketplaces for Codex plugins.
        The attribute name becomes the marketplace name, and the value is either:
        - A path to the marketplace directory
        - The marketplace package, whether a nix package or the output of a fetcher

        Marketplaces are configured through {file}`CODEX_HOME/config.toml`.
      '';
      example = lib.literalExpression ''
        {
          local-marketplace = ./my-local-marketplace;
          gh-marketplace = fetchFromGitHub {
            owner = "some-github-org";
            repo = "codex-marketplace";
            rev = "8a873a220b8427b25b03ce1a821593a24e098c34";
            sha256 = "5c2dce95122b5bb73fa547edabbb6c3061c2d193d11e51faecd4d22659e67279";
          };
        }
      '';
    };

    skills = lib.mkOption {
      type = lib.types.either (lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path)) lib.types.path;
      default = { };
      description = ''
        Custom skills for Codex.

        This option can be either:
        - An attribute set defining skills
        - A path to a directory containing skill folders

        If an attribute set is used, the attribute name becomes the
        skill directory name, and the value is either:
        - Inline content as a string (creates a generated skill directory at {file}`<skills-dir>/<name>/`)
        - A path to a file (creates a generated skill directory at {file}`<skills-dir>/<name>/`)
        - A path to a directory (symlinks {file}`<skills-dir>/<name>/` to that directory)

        If a path is used, it is expected to contain one folder per
        skill name, each containing a {file}`SKILL.md`. Each top-level
        skill entry is symlinked into {file}`<skills-dir>/`, leaving
        {file}`<skills-dir>/` itself as a normal directory so unmanaged
        skills can coexist.

        Home Manager manages skills under {file}`CODEX_HOME/skills`
        (typically {file}`~/.codex/skills`, or
        {file}`~/.config/codex/skills` when
        {option}`home.preferXdgDirectories` is enabled).
      '';
      example = lib.literalExpression ''
        {
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
          data-analysis = ./skills/data-analysis;
        }
      '';
    };

    rules = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
      default = { };
      description = ''
        Codex rules files to manage under {file}`CODEX_HOME/rules/`.

        The attribute name becomes the filename, with a {file}`.rules`
        extension added automatically. The value is either:
        - Inline content as a string
        - A path to an existing rules file

        This is useful for declaratively managing persistent
        `prefix_rule()` definitions, including the default
        {file}`default.rules` allow-list Codex writes when you accept
        recurring approvals interactively.
      '';
      example = lib.literalExpression ''
        {
          default = "prefix_rule(pattern = [\"nix\", \"build\"], decision = \"allow\")\n";
          github = ./codex/github.rules;
        }
      '';
    };
  };
}
