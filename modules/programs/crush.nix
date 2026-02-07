{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.crush;
  jsonFormat = pkgs.formats.json { };

  # Recursively filter nulls (keep all non-null values including false)
  filterNulls =
    value:
    if lib.isAttrs value then
      let
        filtered = lib.mapAttrs (n: v: filterNulls v) value;
      in
      lib.filterAttrs (n: v: v != null && v != { } && v != [ ]) filtered
    else if lib.isList value then
      map filterNulls value
    else
      value;

  # Remove transport-specific fields from MCP configs to prevent invalid combinations
  # (stdio servers can't have url/headers; http servers can't have command/args)
  filterMcpServer =
    server:
    let
      filtered = filterNulls server;
      withoutDisabled =
        if filtered ? disabled && filtered.disabled == false then
          removeAttrs filtered [ "disabled" ]
        else
          filtered;
      withType = withoutDisabled // lib.optionalAttrs (!withoutDisabled ? type) { type = "stdio"; };
    in
    if withType.type == "stdio" then
      removeAttrs withType [
        "url"
        "headers"
      ]
    else
      removeAttrs withType [
        "command"
        "args"
        "env"
      ];

  # Transform MCP servers from programs.mcp if integration is enabled
  # Defaults type to "stdio" if command is present (and not explicitly set),
  # or "http" if url is present (and not explicitly set)
  transformedMcpServers = lib.optionalAttrs (cfg.enableMcpIntegration && config.programs.mcp.enable) (
    lib.mapAttrs (
      name: server:
      let
        typeFromTransport = if server ? url then "http" else "stdio";
        withoutDisabled = removeAttrs server [ "disabled" ];
      in
      withoutDisabled // lib.optionalAttrs (!server ? type) { type = typeFromTransport; }
    ) config.programs.mcp.servers
  );

  # Loads secrets from files into env vars at runtime (keeps them out of the Nix store)
  makeSecretLoaderCode =
    secretEnvVars:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: path: ''
        if [ -f "${path}" ]; then
          export ${name}="$(cat ${lib.escapeShellArg path})"
        fi
      '') secretEnvVars
    );
in
{
  meta.maintainers = with lib.maintainers; [ rane ];

  options.programs.crush = {
    enable = lib.mkEnableOption "Crush, an agentic coding CLI from Charmbracelet";

    package = lib.mkPackageOption pkgs "crush" { };

    finalPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      description = ''
        Wraps the crush package to inject secret environment variables at runtime.
        This is the actual package installed to {env}`$PATH`.
        If {option}`secretEnvVars` is empty, this equals {option}`package`.
      '';
    };

    enableMcpIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        When enabled, merges MCP servers from {option}`programs.mcp.servers` into {option}`programs.crush.settings.mcp`.

        Transforms MCP servers from {option}`programs.mcp.servers` to Crush format:
        - If `url` is set, `type` defaults to `"http"`
        - If `command` is set, `type` defaults to `"stdio"`

        Servers explicitly configured in {option}`programs.crush.settings.mcp` take precedence over imported servers.
      '';
    };

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        options = {
          disabled_tools = [
            "bash"
            "sourcegraph"
          ];
          skills_paths = [
            "~/.config/crush/skills"
            "./project-skills"
          ];
          initialize_as = "AGENTS.md";
          attribution = {
            trailer_style = "co-authored-by";
            generated_with = true;
          };
        };
        permissions = {
          allowed_tools = [
            "view"
            "ls"
            "grep"
            "edit"
          ];
        };
        lsp = {
          go.command = "gopls";
          typescript = {
            command = "typescript-language-server";
            args = [ "--stdio" ];
          };
        };
        mcp = {
          filesystem = {
            command = "npx";
            args = [
              "-y"
              "@modelcontextprotocol/server-filesystem"
              "/tmp"
            ];
          };
          github = {
            type = "http";
            url = "https://api.githubcopilot.com/mcp/";
            headers.Authorization = "Bearer $(echo $GH_PAT)";
          };
        };
        providers = {
          deepseek = {
            type = "openai-compat";
            base_url = "https://api.deepseek.com/v1";
            api_key = "$DEEPSEEK_API_KEY";
            models = [
              {
                id = "deepseek-chat";
                name = "Deepseek V3";
                cost_per_1m_in = 0.27;
                cost_per_1m_out = 1.1;
                context_window = 64000;
              }
            ];
          };
        };
      };
      description = ''
        Main JSON configuration for Crush.
        Writes to {file}`$HOME/.config/crush/crush.json`.

        Configure LSP servers ({option}`settings.lsp`), MCP servers ({option}`settings.mcp`),
        AI providers ({option}`settings.providers`), and general options ({option}`settings.options`).

        For sensitive values like API keys, use {option}`secretEnvVars`
        to inject them from files at runtime.

        See <https://github.com/charmbracelet/crush> for full configuration options.
      '';
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
      default = { };
      description = ''
        Agent Skills configuration.
        The attribute name becomes the skill filename. Values can be:
        - Inline content as a string (creates a .md file)
        - A path to a file containing the skill content
        - A path to a directory (symlinked recursively)
        - Empty to create a placeholder
      '';
      example = lib.literalExpression ''
        {
          pdf-processing = '''
            ---
            name: pdf-processing
            description: Extract text and tables from PDF files
            ---

            # PDF Processing

            Use pdfplumber to extract text from PDFs.
          ''';
          xlsx = ./skills/xlsx.md;
          data-analysis = ./skills/data-analysis;
        }
      '';
    };

    skillsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a directory containing skill files for Crush.
        Symlinks skill files from this directory to ~/.config/crush/skills/.
      '';
      example = lib.literalExpression "./skills";
    };

    secretEnvVars = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = ''
        Environment variables to inject from files at runtime.
        Use this for secure secret management with tools like sops-nix and agenix.

        The attribute name is the environment variable name, and the value
        is the path to a file containing the secret.
      '';
      example = lib.literalExpression ''
        {
          ANTHROPIC_API_KEY = config.sops.secrets.anthropic-api-key.path;
          OPENAI_API_KEY = config.sops.secrets.openai-api-key.path;
          DEEPSEEK_API_KEY = config.age.secrets.deepseek-api-key.path;
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(cfg.skills != { } && cfg.skillsDir != null);
        message = "Cannot specify both `programs.crush.skills` and `programs.crush.skillsDir`";
      }
    ];

    programs.crush.finalPackage =
      if cfg.secretEnvVars != { } then
        pkgs.writeShellScriptBin "crush" ''
          ${makeSecretLoaderCode cfg.secretEnvVars}
          exec ${lib.getExe cfg.package} "$@"
        ''
      else
        cfg.package;

    home = {
      packages = [ cfg.finalPackage ];

      file =
        let
          # Filter and process settings sections
          filteredSettings =
            let
              # Filter LSP section
              withLsp =
                if cfg.settings ? lsp then
                  cfg.settings // { lsp = lib.mapAttrs (n: v: filterNulls v) cfg.settings.lsp; }
                else
                  cfg.settings;

              # Filter and merge MCP section
              withMcp =
                let
                  settingsMcp = cfg.settings.mcp or { };
                  combined = transformedMcpServers // settingsMcp;
                  filteredMcp = lib.mapAttrs (n: v: filterMcpServer v) combined;
                in
                if filteredMcp != { } then withLsp // { mcp = filteredMcp; } else withLsp;

              # Filter providers section
              withProviders =
                if cfg.settings ? providers then
                  withMcp // { providers = lib.mapAttrs (n: v: filterNulls v) cfg.settings.providers; }
                else
                  withMcp;
            in
            filterNulls withProviders;

          finalConfig = filteredSettings;
        in
        {
          ".config/crush/crush.json" = lib.mkIf (finalConfig != { }) {
            source = jsonFormat.generate "crush-config.json" finalConfig;
          };

          ".config/crush/skills" = lib.mkIf (cfg.skillsDir != null) { source = cfg.skillsDir; };
        }
        // lib.optionalAttrs (cfg.skills != { } && cfg.skillsDir == null) (
          lib.mapAttrs' (
            name: content:
            if lib.isPath content && lib.pathIsDirectory content then
              lib.nameValuePair ".config/crush/skills/${name}" {
                source = content;
                recursive = true;
              }
            else
              lib.nameValuePair ".config/crush/skills/${name}.md" (
                if lib.isPath content then { source = content; } else { text = content; }
              )
          ) cfg.skills
        );
    };
  };
}
