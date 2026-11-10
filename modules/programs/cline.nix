{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) literalExpression mkOption;

  upstreamConfigDir = "${config.home.homeDirectory}/.cline";

  jsonFormat = pkgs.formats.json { };

  cfg = config.programs.cline;

  settingsDir = "${cfg.configDir}/data/settings";

  toClineMcpServer =
    server:
    let
      enabled = server.enabled or null;
    in
    removeAttrs server [ "enabled" ]
    # Cline has no `enabled` field, only `disabled`
    // lib.optionalAttrs (enabled != null) { disabled = !enabled; }
    # Cline's transport types are `stdio` and `streamableHttp`
    // lib.optionalAttrs ((server.type or null) == "http") { type = "streamableHttp"; };

  transformMcpServer =
    name: server:
    toClineMcpServer (
      lib.hm.mcp.transformMcpServer {
        inherit server;
        extraTransforms = [
          lib.hm.mcp.addType
          # Cline doesn't support reading environment variables from files
          (lib.hm.mcp.wrapEnvFilesCommand { inherit pkgs name; })
        ];
      }
    );

  sharedMcpServers = lib.optionalAttrs (
    cfg.enableMcpIntegration && config.programs.mcp.enable
  ) config.programs.mcp.servers;

  mergedMcpServers = (lib.mapAttrs transformMcpServer sharedMcpServers) // cfg.mcpServers;

  mutableFiles =
    lib.optionalAttrs (cfg.providers != { }) {
      "${settingsDir}/providers.json" = {
        staticSettings = jsonFormat.generate "cline-providers.json" cfg.providers;
        jqOperation = "$dynamic * $static";
      };
    }
    // lib.optionalAttrs (cfg.models != { }) {
      "${settingsDir}/models.json" = {
        staticSettings = jsonFormat.generate "cline-models.json" cfg.models;
        jqOperation = "$dynamic * $static";
      };
    };
in
{
  meta.maintainers = [ lib.maintainers.folliehiyuki ];

  options.programs.cline = {
    enable = lib.mkEnableOption "Cline coding agent CLI";

    package = lib.mkPackageOption pkgs "cline" { nullable = true; };

    configDir = mkOption {
      type = lib.types.str;
      default = upstreamConfigDir;
      defaultText = literalExpression ''"''${config.home.homeDirectory}/.cline"'';
      example = literalExpression ''"''${config.xdg.configHome}/cline"'';
      description = ''
        Directory holding Cline's configuration and data files.

        Defaults to {file}`~/.cline`, matching the upstream
        {command}`cline` CLI default. The {env}`CLINE_DIR` environment
        variable is exported automatically whenever the directory
        differs from this default.
      '';
    };

    mutableSettings = mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Make providers.json and models.json files writable. Declared values take
        precedence on activation. Removing a declaration does not remove it from
        the existing file. Stop the application before activation to avoid
        concurrent writes. Comments and formatting are not preserved. Switching
        back to immutable configuration uses Home Manager's normal file
        collision handling.
      '';
    };

    enableMcpIntegration = mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to integrate MCP servers config from
        {option}`programs.mcp.servers` into {option}`programs.cline.mcpServers`.

        Note: Settings defined in {option}`programs.mcp.servers` are merged
        with {option}`programs.cline.mcpServers`, with Cline settings taking
        precedence.
      '';
    };

    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        autoUpdateEnabled = false;
        compactionEnabled = true;
        telemetryOptOut = true;
        tools.web_search.enabled = true;
      };
      description = ''
        JSON configuration written to
        {file}`~/.cline/data/settings/global-settings.json`.
      '';
    };

    providers = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        version = 1;
        modes = { };
        providers.claude-code = {
          settings.provider = "claude-code";
          tokenSource = "manual";
        };
      };
      description = ''
        JSON configuration written to
        {file}`~/.cline/data/settings/providers.json`.
      '';
    };

    models = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        version = 1;
        providers.anthropic = {
          provider = {
            name = "Anthropic (custom)";
            defaultModelId = "claude-haiku-4-5";
            protocol = "anthropic";
            client = "anthropic";
            capabilities = [
              "streaming"
              "tools"
              "reasoning"
              "prompt-cache"
            ];
          };
          models = {
            claude-haiku-4-5 = {
              id = "claude-haiku-4-5";
              name = "Claude Haiku 4.5";
            };
            claude-opus-5-5 = {
              id = "claude-opus-5-5";
              name = "Claude Opus 5.5";
            };
          };
        };
      };
      description = ''
        Discovered models configuration for defined providers written to
        {file}`~/.cline/data/settings/models.json`.
      '';
    };

    mcpServers = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        local-server = {
          command = "node";
          args = [ "/path/to/server.js" ];
          disabled = false;
        };
      };
      description = ''
        MCP (Model Context Protocol) servers configuration written to
        {file}`~/.cline/data/settings/cline_mcp_settings.json` under the
        `mpcServers` key verbatim.

        These values are written to the world-readable Nix store, so avoid
        putting secrets in `env`, `headers`, `args`, or `url`.

        For a local `command` server that takes a secret through an
        environment variable, you can use {option}`programs.mcp.servers` with
        `env.<NAME>.file = "/run/secrets/..."` and enable both
        {option}`programs.mcp.enable` and
        {option}`programs.cline.enableMcpIntegration`. Home Manager then
        wraps the command so it reads the file at startup. This covers
        environment variables of local servers, not credentials in
        arguments, URLs, or headers.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.activation.clineSettings = lib.mkIf (cfg.mutableSettings && mutableFiles != { }) (
      lib.hm.dag.entryAfter [ "linkGeneration" ] (
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            path: file:
            lib.hm.generators.mkImpureConfigMerger {
              inherit pkgs path;
              inherit (file) staticSettings jqOperation;
              format = "json";
              empty = "{}";
              mode = "600";
            }
          ) mutableFiles
        )
      )
    );

    home = {
      packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      sessionVariables = lib.mkIf (cfg.configDir != upstreamConfigDir) {
        CLINE_DIR = cfg.configDir;

        # The variable fallbacks to ~/.cline/apps/kanban without checking CLINE_DIR
        CLINE_KANBAN_DATA_DIR = "${cfg.configDir}/apps/kanban";
      };

      file = lib.mkMerge [
        (lib.mkIf (cfg.settings != { }) {
          "${settingsDir}/global-settings.json".source =
            jsonFormat.generate "cline-global-settings.json" cfg.settings;
        })

        (lib.mkIf (!cfg.mutableSettings) {
          "${settingsDir}/models.json".source = jsonFormat.generate "cline-models.json" cfg.models;
          "${settingsDir}/providers.json".source = jsonFormat.generate "cline-providers.json" cfg.providers;
        })

        (lib.mkIf (mergedMcpServers != { }) {
          "${settingsDir}/cline_mcp_settings.json".source = jsonFormat.generate "cline-mcp-settings.json" {
            mcpServers = mergedMcpServers;
          };
        })
      ];
    };
  };
}
