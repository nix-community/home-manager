{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.programs.codex;

  tomlFormat = pkgs.formats.toml { };
  yamlFormat = pkgs.formats.yaml { };

  packageVersion = if cfg.package != null then lib.getVersion cfg.package else "0.94.0";
  isTomlConfig = lib.versionAtLeast packageVersion "0.2.0";
  isAgentsSkillsSupported = lib.versionAtLeast packageVersion "0.94.0";
  settingsFormat = if isTomlConfig then tomlFormat else yamlFormat;
in
{
  meta.maintainers = with lib.maintainers; [
    delafthi
  ];

  imports = [
    (lib.mkRenamedOptionModule
      [ "programs" "codex" "custom-instructions" ]
      [ "programs" "codex" "context" ]
    )
  ];

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
        See <https://github.com/openai/codex/blob/main/codex-rs/config.md> for supported values.
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
              baseURL = "http://localhost:11434/v1";
              envKey = "OLLAMA_API_KEY";
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

        The skills target directory depends on Codex version:
        - {file}`~/.agents/skills` for Codex >= 0.94.0
        - {file}`~/.codex/skills` for older versions
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

  config =
    let
      useXdgDirectories = config.home.preferXdgDirectories && isTomlConfig;
      xdgConfigHome = lib.removePrefix config.home.homeDirectory config.xdg.configHome;
      configDir = if useXdgDirectories then "${xdgConfigHome}/codex" else ".codex";
      configFileName = if isTomlConfig then "config.toml" else "config.yaml";
      skillsDir = if isAgentsSkillsSupported then ".agents/skills" else "${configDir}/skills";

      # TODO: Remove this workaround once Codex supports symlinked SKILL.md
      # files again. Upstream only supports symlinking the containing skill
      # directory today: https://github.com/openai/codex/issues/10470
      isStorePathString = content: builtins.isString content && lib.hasPrefix builtins.storeDir content;
      isPathLikeContent = content: lib.isPath content || isStorePathString content;
      mkSkillDir =
        content:
        pkgs.writeTextDir "SKILL.md" (
          if isPathLikeContent content then builtins.readFile content else content
        );
      skillSources =
        if builtins.isAttrs cfg.skills then
          cfg.skills
        else if lib.isPath cfg.skills && lib.pathIsDirectory cfg.skills then
          lib.mapAttrs (name: _type: cfg.skills + "/${name}") (builtins.readDir cfg.skills)
        else
          { };
      mkSkillEntry =
        name: content:
        if isPathLikeContent content && lib.pathIsDirectory content then
          lib.nameValuePair "${skillsDir}/${name}" {
            source = content;
          }
        else
          lib.nameValuePair "${skillsDir}/${name}" {
            source = mkSkillDir content;
          };
      mkRuleEntry =
        name: content:
        lib.nameValuePair "${configDir}/rules/${name}.rules" (
          if isPathLikeContent content then { source = content; } else { text = content; }
        );

      transformedMcpServers = lib.optionalAttrs (cfg.enableMcpIntegration && config.programs.mcp.enable) (
        lib.mapAttrs (
          name: server:
          # NOTE: Convert shared programs.mcp fields to Codex config keys:
          # - "disabled" becomes inverse "enabled"
          # - "headers" is renamed to "http_headers"
          # - "envFiles" are wrapped in a shell script that sets environment variables before exec
          # See: https://developers.openai.com/codex/mcp#other-configuration-options
          (lib.hm.mcp.transformMcpServer {
            inherit pkgs name server;
            exclude = [
              "headers"
              "type"
            ];
          })
          // lib.optionalAttrs (server.headers != { }) { http_headers = server.headers; }
        ) config.programs.mcp.servers
      );

      settingMcpServers = lib.attrByPath [ "mcp_servers" ] { } cfg.settings;
      mergedMcpServers = transformedMcpServers // settingMcpServers;
      mergedSettings =
        cfg.settings // lib.optionalAttrs (mergedMcpServers != { }) { mcp_servers = mergedMcpServers; };
    in
    mkIf cfg.enable {
      assertions = [
        {
          assertion = !lib.isPath cfg.skills || lib.pathIsDirectory cfg.skills;
          message = "`programs.codex.skills` must be a directory when set to a path";
        }
        {
          assertion = lib.all (content: !(isPathLikeContent content && lib.pathIsDirectory content)) (
            lib.attrValues cfg.rules
          );
          message = "`programs.codex.rules` attribute values must be files when set to paths";
        }
      ];

      home = {
        packages = mkIf (cfg.package != null) [ cfg.package ];

        file = {
          "${configDir}/${configFileName}" = lib.mkIf (mergedSettings != { }) {
            source = settingsFormat.generate "codex-config" mergedSettings;
          };
          "${configDir}/AGENTS.md" =
            if lib.isPath cfg.context then
              { source = cfg.context; }
            else
              lib.mkIf (cfg.context != "") {
                text = cfg.context;
              };
        }
        // lib.mapAttrs' mkSkillEntry skillSources
        // lib.mapAttrs' mkRuleEntry cfg.rules;

        sessionVariables = mkIf useXdgDirectories {
          CODEX_HOME = "${config.xdg.configHome}/codex";
        };
      };
    };
}
