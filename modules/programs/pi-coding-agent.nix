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
    mkPackageOption
    ;

  cfg = config.programs.pi-coding-agent;

  jsonFormat = pkgs.formats.json { };

  upstreamConfigDir = "${config.home.homeDirectory}/.pi/agent";

  packageWithExtraPackages =
    if cfg.package != null && cfg.extraPackages != [ ] then
      pkgs.symlinkJoin {
        inherit (cfg.package) meta;
        name = "${lib.getName cfg.package}-wrapped-${lib.getVersion cfg.package}";
        paths = [ cfg.package ];
        preferLocalBuild = true;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/pi \
            --suffix PATH : ${lib.makeBinPath cfg.extraPackages}
        '';
      }
    else
      cfg.package;
in
{
  meta.maintainers = with lib.maintainers; [ semi710 ];

  options.programs.pi-coding-agent = {
    enable = mkEnableOption "pi-coding-agent";

    accounts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.home = lib.mkOption {
            type = lib.types.addCheck lib.types.str (
              home:
              home != "" && lib.all (part: part != "" && part != "." && part != "..") (lib.splitString "/" home)
            );
            description = "Account directory relative to the user's home directory.";
          };
        }
      );
      default = { };
      description = ''
        Independent account homes receiving the same declared configuration.
        The `default` account is always included and uses `configDir`.
        Authentication, sessions and other runtime state are not copied.
        Select an additional account by setting PI_CODING_AGENT_DIR
        when launching the agent. Global environment variables select only the
        default account. Do not enroll homes whose state is managed by another
        account-sharing tool.
      '';
      example = lib.literalExpression ''
        {
          work.home = ".pi/work";
        }
      '';
    };

    package = mkPackageOption pkgs "pi-coding-agent" { nullable = true; };

    extraPackages = mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      example = literalExpression "[ pkgs.nodejs pkgs.bun ]";
      description = ''
        Extra packages available to Pi Coding Agent.
        These are added to the PATH of the wrapped pi binary.

        Needed for packages installed by pi (e.g.
        {command}`npm:@termdraw/pi` requires {command}`npm` and
        {command}`bun`).
      '';
    };

    configDir = mkOption {
      type = lib.types.str;
      default = upstreamConfigDir;
      defaultText = literalExpression ''"''${config.home.homeDirectory}/.pi/agent"'';
      example = literalExpression ''"''${config.xdg.configHome}/pi/agent"'';
      description = ''
        Directory holding Pi Coding Agent's configuration files.

        Defaults to {file}`~/.pi/agent`, matching the upstream
        {command}`pi` CLI default. The {env}`PI_CODING_AGENT_DIR`
        environment variable is exported automatically whenever the
        directory differs from this default so the CLI reads
        configuration from the same location.
      '';
    };

    mutableSettings = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Keep settings.json writable. Packages are matched by npm name or Git
        repository, ignoring versions and refs. Declared entries replace matching
        entries in place; other entries keep their relative order. Local paths
        are resolved lexically against the configuration directory, without following
        symlinks. Home-relative paths and local file URLs are also supported.
        Unsupported Git source forms cause activation to fail rather than leave
        a stale pin. The enabledModels list is replaced as a whole when declared.
        Other configuration files remain immutable.

        Declared values take precedence on activation. Removing a declaration does
        not remove it from the existing file. Stop the application before activation
        to avoid concurrent writes. Comments and formatting are not preserved.
        Switching back to immutable configuration uses Home Manager's normal
        file collision handling.
      '';
    };

    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        defaultProvider = "anthropic";
        defaultModel = "claude-sonnet-4-20250514";
        defaultThinkingLevel = "medium";
        theme = "dark";
        packages = [
          "npm:@termdraw/pi"
          "npm:pi-mcp-adapter"
        ];
        compaction = {
          enabled = true;
          reserveTokens = 16384;
          keepRecentTokens = 20000;
        };
        retry = {
          enabled = true;
          maxRetries = 3;
        };
        enabledModels = [
          "claude-*"
          "gpt-4o"
        ];
      };
      description = ''
        Configuration written to
        {file}`~/.pi/agent/settings.json`.
        See <https://pi.dev/docs/latest/settings> for the
        documentation.
      '';
    };

    keybindings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        "tui.editor.cursorUp" = [
          "up"
          "ctrl+p"
        ];
        "tui.editor.cursorDown" = [
          "down"
          "ctrl+n"
        ];
        "tui.editor.deleteWordBackward" = [
          "ctrl+w"
          "alt+backspace"
        ];
      };
      description = ''
        Keybindings configuration written to
        {file}`~/.pi/agent/keybindings.json`.
        See <https://pi.dev/docs/latest/keybindings> for the
        documentation.
      '';
    };

    models = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        providers = {
          ollama = {
            baseUrl = "http://localhost:11434/v1";
            api = "openai-completions";
            apiKey = "ollama";
            models = [ { id = "llama3.1:8b"; } ];
          };
        };
      };
      description = ''
        Custom model providers written to
        {file}`~/.pi/agent/models.json`.

        Each provider entry may contain `baseUrl`,
        `api`, `apiKey`, `compat`, and a `models`
        list with `id`, `name`, `reasoning`, etc.

        See <https://pi.dev/docs/latest/models> for the
        documentation.
      '';
    };

    context = mkOption {
      type = lib.types.either lib.types.lines lib.types.path;
      default = "";
      description = ''
        Global context for Pi Coding Agent.

        The value is either:
        - Inline content as a string
        - A path to a file containing the content

        The configured content is written to
        {file}`AGENTS.md` inside
        {option}`programs.pi-coding-agent.configDir`
        (default {file}`~/.pi/agent/AGENTS.md`).
      '';
      example = literalExpression "./pi-context.md";
    };

    appendSystem = mkOption {
      type = lib.types.either lib.types.lines lib.types.path;
      default = "";
      description = ''
        Additional instructions appended to Pi Coding Agent's system prompt.

        The value is either:
        - Inline content as a string
        - A path to a file containing the content

        The configured content is written to
        {file}`APPEND_SYSTEM.md` inside
        {option}`programs.pi-coding-agent.configDir`
        (default {file}`~/.pi/agent/APPEND_SYSTEM.md`).

        A project-local {file}`.pi/APPEND_SYSTEM.md` takes precedence
        over this file.
      '';
      example = literalExpression "./pi-append-system.md";
    };
  };

  config = mkIf cfg.enable {
    programs.pi-coding-agent.accounts.default.home = lib.mkDefault (
      lib.removePrefix "${config.home.homeDirectory}/" cfg.configDir
    );
    assertions =
      let
        homes = map (account: account.home) (lib.attrValues cfg.accounts);
      in
      [
        {
          assertion = lib.length homes == lib.length (lib.unique homes);
          message = "programs.pi-coding-agent.accounts must use distinct home directories.";
        }
      ];
    home = lib.mkMerge (
      lib.mapAttrsToList (
        name: account:
        let
          cfg = config.programs.pi-coding-agent // {
            configDir = "${config.home.homeDirectory}/${account.home}";
          };
        in
        {
          activation."piCodingAgentMutableSettings${lib.optionalString (name != "default") "-${name}"}" =
            lib.mkIf (cfg.mutableSettings && cfg.settings != { })
              (
                lib.hm.dag.entryAfter [ "linkGeneration" ] (
                  lib.hm.generators.mkImpureConfigMerger {
                    inherit pkgs;
                    format = "json";
                    empty = "{}";
                    mode = "600";
                    path = "${cfg.configDir}/settings.json";
                    staticSettings = jsonFormat.generate "pi-coding-agent-settings.json" cfg.settings;

                    jqOperation = ''
                      ${builtins.toJSON config.home.homeDirectory} as $homeDirectory
                      | ${builtins.toJSON cfg.configDir} as $configDir
                      | ${builtins.readFile ./pi-coding-agent-settings-filter.jq}
                    '';
                  }
                )
              );

          packages = mkIf (packageWithExtraPackages != null) [
            packageWithExtraPackages
          ];

          sessionVariables = lib.mkIf (name == "default" && cfg.configDir != upstreamConfigDir) {
            PI_CODING_AGENT_DIR = cfg.configDir;
          };

          file = lib.mkMerge [
            (mkIf (!cfg.mutableSettings && cfg.settings != { }) {
              "${cfg.configDir}/settings.json".source =
                jsonFormat.generate "pi-coding-agent-settings.json" cfg.settings;
            })

            (mkIf (cfg.keybindings != { }) {
              "${cfg.configDir}/keybindings.json".source =
                jsonFormat.generate "pi-coding-agent-keybindings.json" cfg.keybindings;
            })

            (mkIf (cfg.models != { }) {
              "${cfg.configDir}/models.json".source =
                jsonFormat.generate "pi-coding-agent-models.json" cfg.models;
            })

            (
              if lib.hm.strings.isPathLike cfg.context then
                { "${cfg.configDir}/AGENTS.md".source = cfg.context; }
              else
                (mkIf (cfg.context != "") {
                  "${cfg.configDir}/AGENTS.md".text = cfg.context;
                })
            )

            (
              if lib.hm.strings.isPathLike cfg.appendSystem then
                { "${cfg.configDir}/APPEND_SYSTEM.md".source = cfg.appendSystem; }
              else
                (mkIf (cfg.appendSystem != "") {
                  "${cfg.configDir}/APPEND_SYSTEM.md".text = cfg.appendSystem;
                })
            )
          ];
        }
      ) cfg.accounts
    );
  };
}
