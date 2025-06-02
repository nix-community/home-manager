{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    literalExpression
    ;

  cfg = config.programs.opencommit;

in
{
  meta.maintainers = [ lib.hm.maintainers.jmmaloney4 ];

  options.programs.opencommit = {
    enable = mkEnableOption "OpenCommit AI commit message generator";

    apiKey = mkOption {
      type = types.str;
      description = "API key for OpenAI or Claude (OCO_API_KEY).";
      example = "sk-...";
    };

    language = mkOption {
      type = types.str;
      default = "en";
      description = "Language for commit messages (OCO_LANGUAGE).";
      example = "en";
    };

    model = mkOption {
      type = types.str;
      default = "gpt-4o";
      description = "LLM model to use (OCO_MODEL).";
      example = "gpt-4o";
    };

    promptModule = mkOption {
      type = types.str;
      default = "conventional-commit";
      description = "Prompt module (conventional-commit or @commitlint) (OCO_PROMPT_MODULE).";
      example = "conventional-commit";
    };

    setGitHook = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to set up the OpenCommit git hook (\`oco hook set\`).";
      example = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.opencommit ];

    home.sessionVariables = {
      OCO_API_KEY = cfg.apiKey;
      OCO_LANGUAGE = cfg.language;
      OCO_MODEL = cfg.model;
      OCO_PROMPT_MODULE = cfg.promptModule;
    };

    home.activation.opencommit-git-hook = mkIf cfg.setGitHook ''
      ${lib.getExe pkgs.opencommit} hook set
    '';
  };
}
