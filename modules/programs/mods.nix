{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOrder;

  cfg = config.programs.mods;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [ lib.hm.maintainers.ipsavitsky ];

  options.programs.mods = {
    enable = lib.mkEnableOption "mods";

    package = lib.mkPackageOption pkgs "mods" { };

    settings = lib.mkOption {
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

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."mods/mods.yml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "mods.yml" cfg.settings;
    };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration (
      mkOrder 200 ''
        source <(${cfg.package}/bin/mods completion bash)
      ''
    );

    programs.zsh.initContent = mkIf cfg.enableZshIntegration (
      mkOrder 200 ''
        source <(${cfg.package}/bin/mods completion zsh)
      ''
    );

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration (
      mkOrder 200 ''
        ${cfg.package}/bin/mods completion fish | source
      ''
    );
  };
}
