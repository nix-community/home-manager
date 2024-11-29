{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.lazydocker;

  yamlFormat = pkgs.formats.yaml { };

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

in {
  meta.maintainers = [ maintainers.hausken ];

  options.programs.lazydocker = {
    enable = mkEnableOption
      "lazydocker, a simple terminal UI for both docker and docker compose";

    package = mkPackageOption pkgs "lazydocker" { };

    settings = mkOption {
      type = yamlFormat.type;
      default = {
        commandTemplates.dockerCompose =
          "docker compose"; # Lazydocker uses docker-compose by default which will not work
      };
      example = literalExpression ''
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

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file."Library/Application Support/jesseduffield/lazydocker/config.yml" =
      mkIf (cfg.settings != { } && (isDarwin && !config.xdg.enable)) {
        source = yamlFormat.generate "lazydocker-config" cfg.settings;
      };

    xdg.configFile."lazydocker/config.yml" =
      mkIf (cfg.settings != { } && !(isDarwin && !config.xdg.enable)) {
        source = yamlFormat.generate "lazydocker-config" cfg.settings;
      };
  };
}
