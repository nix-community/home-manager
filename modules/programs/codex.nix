{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.programs.codex;
  remoteControlCfg = cfg.remoteControl;

  tomlFormat = pkgs.formats.toml { };
  yamlFormat = pkgs.formats.yaml { };

  packageVersion = if cfg.package != null then lib.getVersion cfg.package else "0.94.0";
  isTomlConfig = lib.versionAtLeast packageVersion "0.2.0";
  settingsFormat = if isTomlConfig then tomlFormat else yamlFormat;
in
{
  meta.maintainers = [
    lib.maintainers.delafthi
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

    remoteControl = {
      enable = lib.mkEnableOption "the Codex remote-control app-server systemd user service";

      codexHome = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "\${config.home.homeDirectory}/.codex";
        description = ''
          Value for the {env}`CODEX_HOME` environment variable used by the
          remote-control service.

          If unset, this follows the same Codex home directory managed by this
          module.
        '';
      };

      listen = lib.mkOption {
        type = lib.types.str;
        default = "off";
        example = "unix://";
        description = ''
          Local app-server transport endpoint passed to
          {command}`codex app-server --listen`.

          The default disables local transports and exposes only the outbound
          remote-control websocket. Set this to {literal}`unix://` if local
          tools should also be able to connect through the Codex app-server
          control socket.
        '';
      };

      target = lib.mkOption {
        type = lib.types.str;
        default = "default.target";
        description = ''
          Systemd user target that starts the Codex remote-control service.
        '';
      };

      environment = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.nullOr (
            lib.types.oneOf [
              lib.types.bool
              lib.types.int
              lib.types.str
            ]
          )
        );
        default = { };
        description = ''
          Environment variables to set for the Codex remote-control service.

          Sensitive values should be provided through
          [](#opt-programs.codex.remoteControl.environmentFile), since values
          configured here are visible in the Nix store and systemd unit.
        '';
        example = lib.literalExpression ''
          {
            RUST_LOG = "codex_app_server=info";
          }
        '';
      };

      environmentFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = "/run/secrets/codex-remote-control.env";
        description = ''
          Additional environment file as defined in {manpage}`systemd.exec(5)`.

          This can be used for machine-local settings that should not be
          written into the generated systemd unit.
        '';
      };

      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        example = lib.literalExpression "with pkgs; [ gitMinimal nix openssh ]";
        description = ''
          Extra packages to add to {env}`PATH` for commands launched by Codex.

          The service also includes the Home Manager profile in {env}`PATH`.
        '';
      };

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "--analytics-default-enabled"
        ];
        description = ''
          Additional arguments passed to {command}`codex app-server`.
        '';
      };
    };
  };

  config =
    let
      useXdgDirectories = config.home.preferXdgDirectories && isTomlConfig;
      xdgConfigHome = lib.removePrefix config.home.homeDirectory config.xdg.configHome;
      configDir = if useXdgDirectories then "${xdgConfigHome}/codex" else ".codex";
      configFileName = if isTomlConfig then "config.toml" else "config.yaml";
      skillsDir = "${configDir}/skills";
      codexHome =
        if remoteControlCfg.codexHome != null then
          remoteControlCfg.codexHome
        else if useXdgDirectories then
          "${config.xdg.configHome}/codex"
        else
          "${config.home.homeDirectory}/.codex";
      remoteControlPath = lib.makeSearchPath "bin" (
        [
          config.home.profileDirectory
        ]
        ++ remoteControlCfg.extraPackages
      );
      remoteControlEnvironment = {
        CODEX_HOME = codexHome;
        PATH = remoteControlPath;
      }
      // remoteControlCfg.environment;
      remoteControlEnvironmentList = lib.mapAttrsToList (
        name: value: "${name}=${if lib.isBool value then lib.boolToString value else toString value}"
      ) (lib.filterAttrs (_name: value: value != null) remoteControlEnvironment);

      # TODO: Remove this workaround once Codex supports symlinked SKILL.md
      # files again. Upstream only supports symlinking the containing skill
      # directory today: https://github.com/openai/codex/issues/10470
      isStorePathString =
        content: builtins.isString content && lib.hasPrefix "${builtins.storeDir}/" content;
      isPathLikeContent = content: lib.isPath content || isStorePathString content;
      mkSkillDir =
        content:
        pkgs.writeTextDir "SKILL.md" (
          if isPathLikeContent content then builtins.readFile content else content
        );
      skillSources =
        if builtins.isAttrs cfg.skills then
          cfg.skills
        else if isPathLikeContent cfg.skills && lib.pathIsDirectory cfg.skills then
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
          _name: server:
          # NOTE: Convert shared programs.mcp fields to Codex config keys:
          # - removeAttrs drops keys that Codex does not use directly
          # - "disabled" becomes inverse "enabled"
          # - "headers" is renamed to "http_headers"
          # See: https://developers.openai.com/codex/mcp#other-configuration-options
          (lib.removeAttrs server [
            "disabled"
            "headers"
          ])
          // (lib.optionalAttrs (server ? headers && !(server ? http_headers)) {
            http_headers = server.headers;
          })
          // {
            enabled = !(server.disabled or false);
          }
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
          assertion = !isPathLikeContent cfg.skills || lib.pathIsDirectory cfg.skills;
          message = "`programs.codex.skills` must be a directory when set to a path";
        }
        {
          assertion = lib.all (content: !(isPathLikeContent content && lib.pathIsDirectory content)) (
            lib.attrValues cfg.rules
          );
          message = "`programs.codex.rules` attribute values must be files when set to paths";
        }
        {
          assertion = !remoteControlCfg.enable || pkgs.stdenv.hostPlatform.isLinux;
          message = "`programs.codex.remoteControl.enable` is only supported on Linux";
        }
        {
          assertion = !remoteControlCfg.enable || cfg.package != null;
          message = "`programs.codex.remoteControl.enable` requires `programs.codex.package` to be set";
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

      systemd.user.services.codex-remote-control =
        mkIf (remoteControlCfg.enable && cfg.package != null && pkgs.stdenv.hostPlatform.isLinux)
          {
            Unit = {
              Description = "Codex remote-control app-server";
              After = [ "network.target" ];
            };

            Service = {
              Environment = remoteControlEnvironmentList;
              ExecStart = lib.escapeShellArgs (
                [
                  (lib.getExe cfg.package)
                  "app-server"
                  "--remote-control"
                  "--listen"
                  remoteControlCfg.listen
                ]
                ++ remoteControlCfg.extraArgs
              );
              Restart = "on-failure";
              RestartSec = 5;
            }
            // lib.optionalAttrs (remoteControlCfg.environmentFile != null) {
              EnvironmentFile = remoteControlCfg.environmentFile;
            };

            Install = {
              WantedBy = [ remoteControlCfg.target ];
            };
          };
    };
}
