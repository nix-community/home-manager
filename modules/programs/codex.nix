{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.programs.codex;

  tomlFormat = pkgs.formats.toml { };
  yamlFormat = pkgs.formats.yaml { };

  packageVersion = if cfg.package != null then lib.getVersion cfg.package else "0.2.0";
  isTomlConfig = lib.versionAtLeast packageVersion "0.2.0";
  settingsFormat = if isTomlConfig then tomlFormat else yamlFormat;
  configFileName = if isTomlConfig then ".codex/config.toml" else ".codex/config.yaml";
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
        Configuration written to {file}`~/.codex/config.toml` (0.2.0+) or {file}`~/.codex/config.yaml` (<0.2.0).
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
      "${configFileName}" = lib.mkIf (cfg.settings != { }) {
        source = settingsFormat.generate "codex-config" cfg.settings;
      };
      ".codex/AGENTS.md" = lib.mkIf (cfg.custom-instructions != "") {
        text = cfg.custom-instructions;
      };
    };
  };

}
