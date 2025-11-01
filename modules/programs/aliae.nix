{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    types
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
    configLocation = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.aliae.yaml";
      defaultText = lib.literalExpression "\${config.home.homeDirectory}/.aliae.yaml";
      example = "/Users/aliae/configs/aliae.yaml";
      description = ''
        Path where aliae should look for its config file. This doesn't override
        where Home-Manager places the generated config file. Changing this option
        could prevent aliae from using the settings defined in your Home-Manager
        configuration.
      '';
    };

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
    assertions = [
      {
        assertion =
          (cfg.settings != { } && cfg.configLocation != null)
          -> lib.hasPrefix config.home.homeDirectory cfg.configLocation;
        message = "The option `programs.aliae.configLocation` must point to a file inside user's home directory when `programs.aliae.settings` is set.";
      }
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    home.sessionVariables = mkIf (cfg.configLocation != null) { ALIAE_CONFIG = cfg.configLocation; };
    home.file."${lib.removePrefix config.home.homeDirectory cfg.configLocation}" =
      mkIf (cfg.settings != { } && lib.hasPrefix config.home.homeDirectory cfg.configLocation)
        {
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
