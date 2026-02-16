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
in
{
  meta.maintainers = with lib.maintainers; [ delafthi ];

  options.programs.mcp = {
    enable = mkEnableOption "mcp";

    servers = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = literalExpression ''
        {
          everything = {
            command = "npx";
            args = [
              "-y"
              "@modelcontextprotocol/server-everything"
            ];
          };
          context7 = {
            url = "https://mcp.context7.com/mcp";
            headers = {
              CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
            };
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
