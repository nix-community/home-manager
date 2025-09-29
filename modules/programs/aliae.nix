{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  inherit (lib.hm.shell)
    mkBashIntegrationOption
    mkZshIntegrationOption
    mkFishIntegrationOption
    mkNushellIntegrationOption
    ;

  cfg = config.programs.aliae;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.aliae = {
    enable = mkEnableOption "aliae";
    package = mkPackageOption pkgs "aliae" { nullable = true; };
    enableBashIntegration = mkBashIntegrationOption { inherit config; };
    enableZshIntegration = mkZshIntegrationOption { inherit config; };
    enableFishIntegration = mkFishIntegrationOption { inherit config; };
    enableNushellIntegration = mkNushellIntegrationOption { inherit config; };
    settings = mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = {
        alias = [
          {
            name = "a";
            value = "aliae";
          }
          {
            name = "hello-world";
            value = ''echo "hello world"'';
            type = "function";
          }
        ];

        env = [
          {
            name = "EDITOR";
            value = "code-insiders --wait";
          }
        ];
      };
      description = ''
        Configuration settings for aliae. All the available options can be found here:
        <https://aliae.dev/docs/setup/configuration#example>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    home.file.".aliae.yaml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "aliae.yaml" cfg.settings;
    };
    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''eval "$(aliae init bash)"'';
    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''eval "$(aliae init zsh)"'';
    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration "aliae init fish | source";
    programs.nushell = mkIf cfg.enableNushellIntegration {
      extraConfig = "source ~/.aliae.nu";
      extraEnv = "aliae init nu";
    };
  };
}
