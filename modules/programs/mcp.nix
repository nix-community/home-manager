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
    ;

  cfg = config.programs.mcp;
  jsonFormat = pkgs.formats.json { };

  serverModule = lib.types.submodule {
    options = {
      command = mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Executable for a local (stdio) MCP server.
          Mutually exclusive with {option}`url`.
        '';
        example = "npx";
      };

      args = mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Arguments passed to {option}`command`.
          Only valid for local servers.
        '';
        example = [
          "-y"
          "@modelcontextprotocol/server-everything"
        ];
      };

      env = mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = ''
          Environment variables set when spawning the MCP server.
          Values are literal strings.
          For file-based secrets use {option}`envFiles`.
          Only valid for local servers.
        '';
        example = literalExpression ''
          { API_BASE_URL = "https://api.example.com"; }
        '';
      };

      envFiles = mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = ''
          Environment variables whose values are read from files at startup.
          Maps variable names to file paths (e.g. sops-nix, systemd credentials).

          This is a Home Manager abstraction — it is NOT written to
          {file}`mcp.json`. Consumer modules must handle it explicitly.
          Only valid for local servers.
        '';
        example = literalExpression ''
          { FORGEJO_ACCESS_TOKEN = "/run/secrets/forgejo_token"; }
        '';
      };

      url = mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          HTTP(S) endpoint for a remote (SSE/HTTP) MCP server.
          Mutually exclusive with {option}`command`.
        '';
        example = "https://mcp.context7.com/mcp";
      };

      headers = mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = ''
          HTTP headers for requests to a remote MCP server.
          Only valid for remote servers.
        '';
        example = literalExpression ''
          { Authorization = "{env:MY_API_KEY}"; }
        '';
      };

      disabled = mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether this MCP server is disabled. Disabled servers remain in the
          configuration but are not started.
        '';
      };
    };
  };

  # Transform typed server to JSON representation.
  # envFiles is intentionally excluded — it is a HM-only abstraction.
  toJsonServer =
    _name: server:
    lib.optionalAttrs (server.command != null) { inherit (server) command; }
    // lib.optionalAttrs (server.args != [ ]) { inherit (server) args; }
    // lib.optionalAttrs (server.env != { }) { inherit (server) env; }
    // lib.optionalAttrs (server.url != null) { inherit (server) url; }
    // lib.optionalAttrs (server.headers != { }) { inherit (server) headers; }
    // lib.optionalAttrs server.disabled { disabled = true; };

in
{
  meta.maintainers = with lib.maintainers; [
    delafthi
    malik
  ];

  options.programs.mcp = {
    enable = mkEnableOption "mcp";

    servers = mkOption {
      type = lib.types.attrsOf serverModule;
      default = { };
      example = literalExpression ''
        {
          everything = {
            command = "npx";
            args = [ "-y" "@modelcontextprotocol/server-everything" ];
          };
          context7 = {
            url = "https://mcp.context7.com/mcp";
            headers.Authorization = "{env:CONTEXT7_API_KEY}";
          };
          codeberg = {
            command = "/path/to/forgejo-mcp";
            args = [ "transport" "stdio" "--url" "https://codeberg.org" ];
            envFiles.FORGEJO_ACCESS_TOKEN = "/run/secrets/codeberg_token";
          };
        }
      '';
      description = ''
        MCP server configurations written to {file}`$XDG_CONFIG_HOME/mcp/mcp.json`.

        Each server is either a local (stdio) server via {option}`command`
        or a remote (HTTP/SSE) server via {option}`url`.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = lib.concatLists (
      lib.mapAttrsToList (name: server: [
        {
          assertion = (server.command != null) != (server.url != null);
          message = ''
            programs.mcp.servers.${name}: exactly one of `command` or `url` must be set.
          '';
        }
        {
          assertion =
            server.url == null || (server.args == [ ] && server.env == { } && server.envFiles == { });
          message = ''
            programs.mcp.servers.${name}: `args`, `env`, and `envFiles` are only valid for local servers (`command`).
          '';
        }
        {
          assertion = server.command == null || server.headers == { };
          message = ''
            programs.mcp.servers.${name}: `headers` is only valid for remote servers (`url`).
          '';
        }
      ]) cfg.servers
    );

    xdg.configFile = mkIf (cfg.servers != { }) {
      "mcp/mcp.json".source = jsonFormat.generate "mcp.json" {
        mcpServers = lib.mapAttrs toJsonServer cfg.servers;
      };
    };
  };
}
