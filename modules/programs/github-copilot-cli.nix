{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    ;

  cfg = config.programs.github-copilot-cli;

  jsonFormat = pkgs.formats.json { };

  upstreamConfigDir = "${config.home.homeDirectory}/.copilot";

  isStorePathString =
    content: builtins.isString content && lib.hasPrefix "${builtins.storeDir}/" content;

  isPathLikeContent = content: lib.isPath content || isStorePathString content;

  transformSingleServer =
    _name: server:
    let
      server' = removeAttrs server [ "disabled" ];
      type = server'.type or (if server' ? url then "http" else "local");
    in
    server'
    // {
      inherit type;
    }
    // lib.optionalAttrs (type == "local") {
      args = server'.args or [ ];
    }
    // lib.optionalAttrs (!(server' ? tools)) {
      tools = [ "*" ];
    };

  transformedMcpServers =
    if cfg.enableMcpIntegration && config.programs.mcp.enable && config.programs.mcp.servers != { } then
      lib.mapAttrs transformSingleServer (
        lib.filterAttrs (
          _: server: !(server.disabled or false) && (server ? url || server ? command)
        ) config.programs.mcp.servers
      )
    else
      { };

  mergedMcpServers = transformedMcpServers // cfg.mcpServers;
in
{
  meta.maintainers = [ lib.maintainers.ojsef39 ];

  options.programs.github-copilot-cli = {
    enable = mkEnableOption "GitHub Copilot CLI";

    package = mkPackageOption pkgs "github-copilot-cli" { nullable = true; };

    configDir = mkOption {
      type = lib.types.str;
      default =
        if config.home.preferXdgDirectories then "${config.xdg.configHome}/copilot" else upstreamConfigDir;
      defaultText = literalExpression ''
        if config.home.preferXdgDirectories then
          "''${config.xdg.configHome}/copilot"
        else
          "''${config.home.homeDirectory}/.copilot"
      '';
      example = literalExpression ''"''${config.xdg.configHome}/copilot"'';
      description = ''
        Directory holding Copilot CLI configuration files such as
        {file}`config.json`, {file}`mcp-config.json`, and
        {file}`copilot-instructions.md`.

        Defaults to `''${config.xdg.configHome}/copilot` when
        {option}`home.preferXdgDirectories` is enabled and to `~/.copilot`
        otherwise. The {env}`COPILOT_HOME` environment variable is exported
        automatically whenever the directory differs from the upstream
        default of `~/.copilot`.

        See <https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference#changing-the-location-of-the-configuration-directory>.
      '';
    };

    enableMcpIntegration = mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to integrate the MCP servers config from
        {option}`programs.mcp.servers` into
        {option}`programs.github-copilot-cli.mcpServers`.

        Servers defined in {option}`programs.mcp.servers` are merged with
        {option}`programs.github-copilot-cli.mcpServers`, with the latter
        taking precedence. Disabled servers (where `disabled = true`) are
        excluded from the generated configuration.
      '';
    };

    settings = mkOption {
      type = lib.types.attrsOf jsonFormat.type;
      default = { };
      example = literalExpression ''
        {
          model = "claude-sonnet-4-5";
          theme = "default";
          trusted_folders = [ "/home/user/projects" ];
          renderMarkdown = true;
          autoUpdate = false;
        }
      '';
      description = ''
        Configuration written to {file}`config.json` inside
        {option}`programs.github-copilot-cli.configDir`.

        Known configuration keys include:
        - `model` — AI model selection
        - `effortLevel` — reasoning effort for capable models
        - `theme` — `"default"`, `"dim"`, `"high-contrast"`, or `"colorblind"`
        - `mouse` — enable mouse support (default: `true`)
        - `banner` — frequency of animated banner display
        - `renderMarkdown` — markdown rendering toggle (default: `true`)
        - `screenReader` — accessibility optimizations (default: `false`)
        - `autoUpdate` — automatic CLI updates (default: `true`)
        - `stream` — token-by-token response streaming (default: `true`)
        - `includeCoAuthoredBy` — agent commit attribution (default: `true`)
        - `respectGitignore` — exclude gitignored files from file picker
        - `trusted_folders` — list of pre-approved directory paths
        - `allowed_urls`, `denied_urls` — URL allowlists/blocklists
        - `logLevel` — log verbosity
        - `disableAllHooks` — global hook disable toggle
        - `hooks` — inline hook definitions
        - `enabledFeatureFlags` — enable or disable specific feature flags

        See <https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference>
        for the documentation.
      '';
    };

    context = mkOption {
      type = lib.types.either lib.types.lines lib.types.path;
      default = "";
      example = literalExpression ''
        '''
          Review the current workspace before making edits.
          Prefer actionable findings over general commentary.
        '''
      '';
      description = ''
        Global instructions for GitHub Copilot CLI.

        The value is either:
        - Inline content as a string
        - A path to a file containing the content

        The configured content is written to
        {file}`copilot-instructions.md` inside
        {option}`programs.github-copilot-cli.configDir`.
      '';
    };

    mcpServers = mkOption {
      type = lib.types.attrsOf jsonFormat.type;
      default = { };
      example = literalExpression ''
        {
          playwright = {
            type = "local";
            command = "npx";
            args = [ "@playwright/mcp@latest" ];
            tools = [ "*" ];
          };
          context7 = {
            type = "http";
            url = "https://mcp.context7.com/mcp";
            headers = { CONTEXT7_API_KEY = "YOUR-API-KEY"; };
            tools = [ "*" ];
          };
        }
      '';
      description = ''
        MCP server configurations written to {file}`mcp-config.json` inside
        {option}`programs.github-copilot-cli.configDir`.

        Each attribute defines a server entry under `mcpServers` in the config
        file. Supported server types:
        - `local` — starts a local process via stdio (`command`, optional `args`, `env`)
        - `http` — connects to a remote HTTP server (`url`, optional `headers`)
        - `sse` — legacy HTTP with Server-Sent Events (same structure as `http`)

        The `tools` field accepts `["*"]` to enable all tools or a list of
        specific tool names.

        See <https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-mcp-servers>
        for the documentation.
      '';
    };

    agents = mkOption {
      type = lib.types.either (lib.types.attrsOf (
        lib.types.oneOf [
          lib.types.lines
          lib.types.path
          lib.types.str
        ]
      )) lib.types.path;
      default = { };
      example = literalExpression ''
        {
          code-reviewer = '''
            ---
            description: High signal code review for logic, security, and test gaps.
            tools: ["*"]
            ---

            Review the current changes and report only actionable findings.
          ''';
          documentation = ./agents/documentation.agent.md;
        }
      '';
      description = ''
        Custom agents for GitHub Copilot CLI.

        This option can either be:
        - An attribute set defining agents
        - A path to a directory containing multiple agent files

        If an attribute set is used, the attribute name becomes the agent
        filename, and the value is either:
        - Inline content as a string (creates
          {file}`''${configDir}/agents/<name>.agent.md`)
        - A path to a file (creates
          {file}`''${configDir}/agents/<name>.agent.md`)

        If a path is used, it is expected to contain agent files. The directory
        is symlinked to {file}`''${configDir}/agents/`.

        See <https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#custom-agents-reference>
        for the documentation.
      '';
    };

    skills = mkOption {
      type = lib.types.either (lib.types.attrsOf (
        lib.types.oneOf [
          lib.types.lines
          lib.types.path
          lib.types.str
        ]
      )) lib.types.path;
      default = { };
      example = literalExpression ''
        {
          data-analysis = ./skills/data-analysis;
          release-notes = '''
            ---
            name: release-notes
            description: Draft release notes from commits and pull requests.
            ---

            Summarize user-visible changes and call out migrations.
          ''';
        }
      '';
      description = ''
        Custom skills for GitHub Copilot CLI.

        This option can be either:
        - An attribute set defining skills
        - A path to a directory containing skill folders

        If an attribute set is used, the attribute name becomes the skill
        directory name, and the value is either:
        - Inline content as a string (creates
          {file}`''${configDir}/skills/<name>/SKILL.md`)
        - A path to a file (creates
          {file}`''${configDir}/skills/<name>/SKILL.md`)
        - A path to a directory (symlinks
          {file}`''${configDir}/skills/<name>/` to that directory)

        If a path is used, it is expected to contain one folder per skill name,
        each containing a {file}`SKILL.md`. The directory is symlinked to
        {file}`''${configDir}/skills/`.

        See <https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#skills-reference>
        for the documentation.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !isPathLikeContent cfg.agents || lib.pathIsDirectory cfg.agents;
        message = "`programs.github-copilot-cli.agents` must be a directory when set to a path";
      }
      {
        assertion = !isPathLikeContent cfg.skills || lib.pathIsDirectory cfg.skills;
        message = "`programs.github-copilot-cli.skills` must be a directory when set to a path";
      }
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    home.file = {
      # NOTE: Copilot will try to add a firstLaunchAt date and crash if the
      # file exists but does not have this key set. Only generate the file when
      # the user has explicitly configured settings, and always inject the
      # default so the managed file stays valid.
      "${cfg.configDir}/config.json" = mkIf (cfg.settings != { }) {
        source = jsonFormat.generate "github-copilot-cli-config.json" (
          { firstLaunchAt = "1970-01-01T00:00:00.000Z"; } // cfg.settings
        );
      };

      "${cfg.configDir}/mcp-config.json" = mkIf (mergedMcpServers != { }) {
        source = jsonFormat.generate "github-copilot-cli-mcp-config.json" {
          mcpServers = mergedMcpServers;
        };
      };

      "${cfg.configDir}/copilot-instructions.md" =
        if isPathLikeContent cfg.context then
          { source = cfg.context; }
        else
          mkIf (cfg.context != "") {
            text = cfg.context;
          };

      "${cfg.configDir}/agents" = mkIf (isPathLikeContent cfg.agents) {
        source = cfg.agents;
        recursive = true;
      };

      "${cfg.configDir}/skills" = mkIf (isPathLikeContent cfg.skills) {
        source = cfg.skills;
        recursive = true;
      };
    }
    // lib.optionalAttrs (builtins.isAttrs cfg.agents) (
      lib.mapAttrs' (
        name: content:
        lib.nameValuePair "${cfg.configDir}/agents/${name}.agent.md" (
          if isPathLikeContent content then { source = content; } else { text = content; }
        )
      ) cfg.agents
    )
    // lib.optionalAttrs (builtins.isAttrs cfg.skills) (
      lib.mapAttrs' (
        name: content:
        if isPathLikeContent content && lib.pathIsDirectory content then
          lib.nameValuePair "${cfg.configDir}/skills/${name}" {
            source = content;
            recursive = true;
          }
        else
          lib.nameValuePair "${cfg.configDir}/skills/${name}/SKILL.md" (
            if isPathLikeContent content then { source = content; } else { text = content; }
          )
      ) cfg.skills
    );

    home.sessionVariables = mkIf (cfg.configDir != upstreamConfigDir) {
      COPILOT_HOME = cfg.configDir;
    };
  };
}
