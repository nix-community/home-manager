{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    literalExpression
    ;

  inherit (lib.types) submodule;

  inherit (pkgs.formats) json;

  jsonFormat = json { };

  cfg = config.programs.charm-freeze;
in
{
  options.programs.charm-freeze = {
    enable = mkEnableOption "Enable pianobar";

    package = mkPackageOption pkgs "charm-freeze" {
      nullable = true;
    };

    settings = mkOption {
      default = { };

      description = ''
        Attribute set of named configuration files to write.
      '';

      example = literalExpression ''
        {
          programs.charm-freeze = {
            enable = true;

            settings.user = {
              background = "#171717";
              margin = [0 0 0 0];
              padding = [20 40 20 20];
              window = false;
              width = 0;
              height = 0;
              config = "default";
              theme = "gruvbox-dark";
              border = { radius = 0; width = 0; color = "#515151"; };
              shadow = { blur = 0; x = 0; y = 0; };
              font = {
                family = "Liberation Mono";
                file = "''${pkgs.liberation_ttf_v2}/share/fonts/truetype/LiberationMono-Regular.ttf";
                size = 14;
                ligatures = false;
              };
              line_height = 1.2;
              line_numbers = false;
            };
          };
        }
      '';

      type = lib.types.attrsOf (submodule {
        freeformType = jsonFormat.type;
      });

    };
  };

  config = mkIf cfg.enable {
    xdg.configFile = lib.mkIf (cfg.settings != { }) (
      lib.listToAttrs (
        lib.mapAttrsToList (name: value: {
          name = "charm-freeze/${name}.json";
          value.source = jsonFormat.generate "charm-freeze-config-${name}" value;
        }) cfg.settings
      )
    );

    home.packages = mkIf (cfg.package != null) [
      cfg.package
    ];
  };

  meta.maintainers = [
    lib.maintainers.S0AndS0
  ];
}
