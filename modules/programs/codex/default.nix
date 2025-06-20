{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.programs.codex;

  settingsFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [
    lib.hm.maintainers.delafthi
  ];

  options.programs.codex = {
    enable = lib.mkEnableOption "Lightweight coding agent that runs in your terminal";

    package = lib.mkPackageOption pkgs "codex" { nullable = true; };

    settings = lib.mkOption {
      inherit (settingsFormat) type;
      description = ''
        Configuration written to {file}`~/.codex/config.yaml`.
        See <https://github.com/openai/codex#configuration-guide> for supported values.
      '';
      default = { };
      defaultText = lib.literalExpression "{ }";
      example = lib.literalExpression ''
        {
          model = "gemma3:latest";
          provider = "ollama";
          providers = {
            ollama = {
              name = "Ollama";
              baseURL = "http://localhost:11434/v1";
              envKey = "OLLAMA_API_KEY";
            };
          };
        }
      '';
    };
    custom-instructions = lib.mkOption {
      type = lib.types.lines;
      description = "Define custom guidance for the agents; this value is written to {file}~/.codex/AGENTS.md";
      default = "";
      example = lib.literalExpression ''
        '''
          - Always respond with emojis
          - Only use git commands when explicitly requested
        '''
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    home.file = {
      ".codex/config.yaml".source = settingsFormat.generate "codex-config" cfg.settings;
      ".codex/AGENTS.md".text = cfg.custom-instructions;
    };
  };

}
