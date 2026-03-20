{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.programs.aichat;

  settingsFormat = pkgs.formats.yaml { };

  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  meta.maintainers = [
    lib.maintainers.jaredmontoya
  ];

  options.programs.aichat = {
    enable = lib.mkEnableOption "aichat, an All-in-one LLM CLI tool";

    package = lib.mkPackageOption pkgs "aichat" { nullable = true; };

    settings = lib.mkOption {
      inherit (settingsFormat) type;
      default = { };
      defaultText = lib.literalExpression "{ }";
      example = lib.literalExpression ''
        {
          model = "ollama:mistral-small3.1:latest";
          clients = [
            {
              type = "openai-compatible";
              name = "ollama";
              api_base = "http://localhost:11434/v1";
              models = [
                {
                  name = "mistral-small3.1:latest";
                  supports_function_calling = true;
                  supports_vision = true;
                }
              ];
            }
          ];
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/aichat/config.yaml`
        on Linux or on Darwin if [](#opt-xdg.enable) is set, otherwise
        {file}`~/Library/Application Support/aichat/config.yaml`.
        See
        <https://github.com/sigoden/aichat/blob/main/config.example.yaml>
        for supported values.
      '';
    };

    agents = lib.mkOption {
      type = lib.types.attrsOf settingsFormat.type;
      default = { };
      example = {
        openai = {
          model = "openai:gpt-4o";
          temperature = 0.5;
          top_p = 0.7;
          use_tools = "fs,web_search";
          agent_prelude = "default";
        };

        llama = {
          model = "llama3.2:latest";
          temperature = 0.5;
          use_tools = "web_search";
        };
      };
      description = ''
        Agent-specific configurations. See
        <https://github.com/sigoden/aichat/wiki/Configuration-Guide#agent-specific>
        for supported values.
      '';
    };
  };

  config =
    let
      aichatConfigPath =
        if (isDarwin && !config.xdg.enable) then
          "Library/Application Support/aichat"
        else
          "${lib.removePrefix config.home.homeDirectory config.xdg.configHome}/aichat";
    in
    mkIf cfg.enable {
      home.packages = mkIf (cfg.package != null) [ cfg.package ];
      home.file = {
        "${aichatConfigPath}/config.yaml" = mkIf (cfg.settings != { }) {
          source = settingsFormat.generate "aichat-config" cfg.settings;
        };
      }
      // (lib.mapAttrs' (
        k: v:
        lib.nameValuePair "${aichatConfigPath}/agents/${k}/config.yaml" {
          source = settingsFormat.generate "aichat-agent-${k}" v;
        }
      ) cfg.agents);
    };
}
