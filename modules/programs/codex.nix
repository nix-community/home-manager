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
in
{
  meta.maintainers = [
    lib.maintainers.delafthi
  ];

  options.programs.codex = {
    enable = lib.mkEnableOption "Lightweight coding agent that runs in your terminal";

    package = lib.mkPackageOption pkgs "codex" { nullable = true; };

    settings = lib.mkOption {
      type = tomlFormat.type;
      description = ''
        Configuration written to {file}`CODEX_HOME/config.toml`. Per default {env}`CODEX_HOME`
        设为 ~/.codex；开启 {option}`home.preferXdgDirectories` 时写入 {file}`~/.config/codex/`。
        详见 <https://github.com/openai/codex/blob/main/codex-rs/config.md>。
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

  config =
    let
      useXdgDirectories = config.home.preferXdgDirectories;
      xdgConfigHome = lib.removePrefix config.home.homeDirectory config.xdg.configHome;
      configDir = if useXdgDirectories then "${xdgConfigHome}/codex" else ".codex";
    in
    mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.package == null || lib.versionAtLeast (lib.getVersion cfg.package) "0.2.0";
          message = "programs.codex requires codex >= 0.2.0 (TOML config only)";
        }
      ];

      home = {
        packages = mkIf (cfg.package != null) [ cfg.package ];
        file = {
          "${configDir}/config.toml" = lib.mkIf (cfg.settings != { }) {
            source = tomlFormat.generate "codex-config" cfg.settings;
          };
          "${configDir}/AGENTS.md" = lib.mkIf (cfg.custom-instructions != "") {
            text = cfg.custom-instructions;
          };
        };
        sessionVariables = mkIf useXdgDirectories {
          CODEX_HOME = "${config.xdg.configHome}/codex";
        };
      };
    };
}
