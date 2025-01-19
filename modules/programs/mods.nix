{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.mods;
  yamlFormat = pkgs.formats.yaml { };
in {
  meta.maintainers = [ ];

  options.programs.mods = {
    enable = mkEnableOption "mods";

    package = mkOption {
      type = types.package;
      default = pkgs.mods;
      defaultText = literalExpression "pkgs.mods";
      description = "The mods package to install";
    };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      example = ''
        {
          default-model = "llama3.2";
          apis = {
            ollama = {
              base-url = "http://localhost:11434/api";
              models = {
                "llama3.2" = {
                  max-input-chars = 650000;
                };
              };
            };
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/mods/mods.yml`.

        See <https://github.com/charmbracelet/mods/blob/main/config_template.yml> for the full
        list of options.
      '';
    };

    enableBashIntegration = mkEnableOption "Bash integration" // {
      default = false;
    };

    enableZshIntegration = mkEnableOption "Zsh integration" // {
      default = false;
    };

    enableFishIntegration = mkEnableOption "Fish integration" // {
      default = false;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."mods/mods.yml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "mods.yml" cfg.settings;
    };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration (mkOrder 200 ''
      source <(${pkgs.mods}/bin/mods completion bash)
    '');

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration (mkOrder 200 ''
      source <(${pkgs.mods}/bin/mods completion zsh)
    '');

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration
      (mkOrder 200 ''
        ${pkgs.mods}/bin/mods completion fish | source
      '');
  };
}
