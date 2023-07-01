{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.k9s;
  yamlFormat = pkgs.formats.yaml { };

in {
  meta.maintainers = [ hm.maintainers.katexochen ];

  options.programs.k9s = {
    enable =
      mkEnableOption "k9s - Kubernetes CLI To Manage Your Clusters In Style";

    package = mkPackageOption pkgs "k9s" { };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/k9s/config.yml`. See
        <https://k9scli.io/topics/config/>
        for supported values.
      '';
      example = literalExpression ''
        k9s = {
          refreshRate = 2;
        };
      '';
    };

    skin = mkOption {
      type = yamlFormat.type;
      default = { };
      description = ''
        Skin written to
        {file}`$XDG_CONFIG_HOME/k9s/skin.yml`. See
        <https://k9scli.io/topics/skins/>
        for supported values.
      '';
      example = literalExpression ''
        k9s = {
          body = {
            fgColor = "dodgerblue";
          };
        };
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."k9s/config.yml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "k9s-config" cfg.settings;
    };

    xdg.configFile."k9s/skin.yml" = mkIf (cfg.skin != { }) {
      source = yamlFormat.generate "k9s-skin" cfg.skin;
    };
  };
}
