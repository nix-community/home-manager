{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.posting;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [ lib.hm.maintainers.reesilva ];

  options.programs.posting = {
    enable = lib.mkEnableOption "Posting";

    package = lib.mkPackageOption pkgs "posting" { nullable = true; };

    settings = lib.mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          theme = "custom";
          layout = "horizontal";
          response = {
            prettify_json = false;
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/posting/config.yaml`.

        See <https://posting.sh/guide/configuration/>
        for supported values.
      '';
    };

    themes = lib.mkOption {
      type =
        with lib.types;
        attrsOf (oneOf [
          yamlFormat.type
          path
          lines
        ]);
      default = { };
      example = lib.literalExpression ''
        {
          custom = {
            name = "custom";
            primary = "#4e78c4";
            secondary = "#f39c12";
            accent = "#e74c3c";
            background = "#0e1726";
            surface = "#17202a";
            error = "#e74c3c";
            success = "#2ecc71";
            warning = "#f1c40f";
          };
        }
      '';
      description = ''
        Each theme is written to
        {file}`$XDG_DATA_HOME/posting/themes/NAME.yaml`.

        See <https://posting.sh/guide/themes/>
        for more information.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."posting/config.yaml" = lib.mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "posting-config.yaml" cfg.settings;
    };

    xdg.dataFile = lib.mkIf (cfg.themes != { }) (
      lib.mapAttrs' (
        name: value:
        lib.nameValuePair "posting/themes/${name}.yaml" {
          source =
            if builtins.isPath value || lib.isStorePath value then
              value
            else if lib.isString value then
              pkgs.writeText "posting-theme-${name}.yaml" value
            else
              yamlFormat.generate "posting-theme-${name}.yaml" value;
        }
      ) cfg.themes
    );
  };
}
