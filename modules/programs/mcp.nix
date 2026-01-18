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

  cfg = config.programs.mcp;

  jsonFormat = pkgs.formats.json { };

  stdioServerType = types.addCheck (types.submodule {
    options = {
      type = mkOption {
        type = types.enum [ "stdio" ];
      };

      command = mkOption {
        type = types.str;
        description = "Command to run the MCP server";
        example = "npx";
      };

      args = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Arguments to pass to the MCP server command";
        example = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "/home/user"
        ];
      };

      env = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Environment variables for the MCP server";
        example = {
          GITHUB_TOKEN = "ghp_xxxxxxxxxxxx";
        };
      };

      enabled = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable this MCP server";
      };

      timeout = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Timeout in milliseconds for server operations";
        example = 5000;
      };
    };
  }) (server: server.type or null == "stdio");

  remoteServerType = types.addCheck (types.submodule {
    options = {
      type = mkOption {
        type = types.enum [
          "sse"
          "http"
        ];
      };

      url = mkOption {
        type = types.str;
        description = "Server endpoint URL";
        example = "https://example.com/mcp";
      };

      headers = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "HTTP headers for authentication";
        example = {
          Authorization = "Bearer token123";
        };
      };

      enabled = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable this MCP server";
      };

      timeout = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Timeout in milliseconds for server operations";
        example = 5000;
      };
    };
  }) (server: server.type or null == "sse" || server.type or null == "http");

  mcpServerType = types.oneOf [
    stdioServerType
    remoteServerType
  ];
in
{
  meta.maintainers = with lib.maintainers; [ delafthi ];

  options.programs.mcp = {
    enable = mkEnableOption "mcp";

    servers = mkOption {
      type = types.attrsOf mcpServerType;
      default = { };
      example = literalExpression ''
        {
          everything = {
            type = "stdio";
            command = "npx";
            args = [
              "-y"
              "@modelcontextprotocol/server-everything"
            ];
          };
          context7 = {
            type = "http";
            url = "https://mcp.context7.com/mcp";
            headers = {
              CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
            };
          };
          atlassian = {
            type = "sse";
            url = "https://mcp.atlassian.com/v1/sse";
          };
        }
      '';
      description = ''
        MCP server configurations written to
        {file}`XDG_CONFIG_HOME/mcp/mcp.json`
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile = mkIf (cfg.servers != { }) (
      let
        mcp-config = {
          mcpServers = cfg.servers;
        };
      in
      {
        "mcp/mcp.json".source = jsonFormat.generate "mcp.json" mcp-config;
      }
    );
  };
}
