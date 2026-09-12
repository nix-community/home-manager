{
  config,
  lib,
  # pkgs,
  ...
}:
let
  # TODO: remove following and uncomment `pkgs` above after;
  # - NixOS/nixpkgs# is accepted
  # - nix-community/home-manager is updated
  pkgs = import /home/s0ands0/git/hub/NixOS/nixpkgs/wt/add-go-freeze { };

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

  cfg = config.programs.go-freeze;
in
{
  options.programs.go-freeze = {
    enable = mkEnableOption "Enable pianobar";

    package = mkPackageOption pkgs "go-freeze" {
      nullable = true;
    };

    settings = mkOption {
      default = { };

      description = ''
        Attribute set of named configuration files to write.
      '';

      example = literalExpression ''
        {
          programs.go-freeze = {
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
          name = "go-freeze/${name}.json";
          value.source = jsonFormat.generate "go-freeze-config-${name}" value;
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
