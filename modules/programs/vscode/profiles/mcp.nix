# contains options related to MCP servers
# these are parsed by the parent module (for now)
{
  appName,
  lib,
  moduleName,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.options) mkOption;
in
{

  _class = "homeManager.vscodeProfile";

  options = {

    enableMcpIntegration = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to integrate the MCP servers config from
        {option}`programs.mcp.servers` into
        {option}`${moduleName}.userMcp`.

        Note: Settings defined in {option}`programs.mcp.servers` are merged
        with {option}`${moduleName}.userMcp`, with ${appName}
        settings taking precedence.
      '';
    };

    userMcp = mkOption {
      type = with types; either path json;
      default = { };
      example.servers.Github.url = "https://api.githubcopilot.com/mcp/";
      description = ''
        Configuration written to ${appName}'s
        {file}`mcp.json`.
        This can be a JSON object or a path to a custom JSON file.
      '';
    };

  };

}
