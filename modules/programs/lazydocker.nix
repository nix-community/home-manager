{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.programs.lazydocker;

  yamlFormat = pkgs.formats.yaml { };

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

in
{
  meta.maintainers = [ lib.maintainers.hausken ];

  options.programs.lazydocker = {
    enable = lib.mkEnableOption "lazydocker, a simple terminal UI for both docker and docker compose";

    package = lib.mkPackageOption pkgs "lazydocker" { nullable = true; };

    settings = lib.mkOption {
      type = yamlFormat.type;
      default = {
        commandTemplates.dockerCompose = "docker compose"; # Lazydocker uses docker-compose by default which will not work
      };
      example = lib.literalExpression ''
        {
          gui.theme = {
            activeBorderColor = ["red" "bold"];
            inactiveBorderColor = ["blue"];
          };
          commandTemplates.dockerCompose = "docker compose compose -f docker-compose.yml";
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/lazydocker/config.yml`
        on Linux or on Darwin if [](#opt-xdg.enable) is set, otherwise
        {file}`~/Library/Application Support/jesseduffield/lazydocker/config.yml`.
        See
        <https://github.com/jesseduffield/lazydocker/blob/master/docs/Config.md>
        for supported values.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file."Library/Application Support/jesseduffield/lazydocker/config.yml" =
      lib.mkIf (cfg.settings != { } && (isDarwin && !config.xdg.enable))
        {
          source = yamlFormat.generate "lazydocker-config" cfg.settings;
        };

    xdg.configFile."lazydocker/config.yml" =
      lib.mkIf (cfg.settings != { } && !(isDarwin && !config.xdg.enable))
        {
          source = yamlFormat.generate "lazydocker-config" cfg.settings;
        };
  };
}
