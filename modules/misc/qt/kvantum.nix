{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    concatMapStringsSep
    generators
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    types
    mkPackageOption
    ;

  kvconfigFormat = pkgs.formats.ini {
    listToValue = concatMapStringsSep ", " (generators.mkValueStringDefault { });
  };

  kvconfigAtom = kvconfigFormat.lib.types.atom;

  kvconfigSection = (types.attrsOf kvconfigAtom) // {
    description = "section of a kvconfig file (attrs of ${kvconfigAtom.description})";
  };

  cfg = config.qt.kvantum;
in

{
  meta.maintainers = [ lib.maintainers.claymorwan ];

  options.qt.kvantum = {
    enable = mkEnableOption "Kvantum configuration";
    package = mkPackageOption pkgs.kdePackages "qtstyleplugin-kvantum" { nullable = true; };

    qt5 = {
      enable = mkEnableOption "Kvantum Qt5 support";
      package = mkPackageOption pkgs.libsForQt5 "qtstyleplugin-kvantum" {
        nullable = true;
        extraDescription = ''
          The package to use for Kvantum Qt5 support.
        '';
      };
    };

    settings = mkOption {
      type = types.submodule {
        freeformType = types.attrsOf kvconfigSection;

        options = {
          General = mkOption {
            type = types.submodule {
              freeformType = kvconfigSection;

              options = {
                theme = mkOption {
                  type = with types; nullOr str;
                  default = null;
                  example = "KvAdapta";
                  description = ''
                    The default Kvantum theme to use.
                  '';
                };
              };
            };
            default = { };
            example = {
              theme = "KvAdapta";
            };
            description = ''
              General configuration settings for Kvantum.
            '';
          };

          Applications = mkOption {
            type = with types; attrsOf (listOf str);
            default = { };
            example = {
              KvArc = [
                "app1"
                "app2"
              ];
              KvFlat = [ "app3" ];
            };
            description = ''
              Application configuration settings for Kvantum.

              Themes set here will override {option}`qt.kvantum.settings.General.theme`
              for their specific applications.
            '';
          };
        };
      };
      default = { };
      example = {
        General = {
          theme = "KvAdapta";
        };
        Applications = {
          KvArc = [
            "app1"
            "app2"
          ];
          KvFlat = [ "app3" ];
        };
        SomethingElse = {
          foo = "bar";
        };
      };
      description = ''
        Global configuration settings written to {file}`$XDG_CONFIG_HOME/Kvantum/kvantum.kvconfig`.
      '';
    };

    themes = mkOption {
      type = with types; listOf package;
      default = [ ];
      example = literalExpression ''
        with pkgs; [
          gruvbox-kvantum
          catppuccin-kvantum
        ]'';
      description = ''
        Theme packages to install to {file}`$XDG_CONFIG_HOME/Kvantum/`.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [
      cfg.package
      (mkIf (cfg.qt5.enable && cfg.qt5.package != null) cfg.qt5.package)
    ];

    xdg.configFile = {
      "Kvantum" = mkIf (cfg.themes != [ ]) {
        recursive = true;
        source = pkgs.symlinkJoin {
          name = "kvantum-themes";
          paths = cfg.themes;
          stripPrefix = "/share/Kvantum";
        };
      };

      "Kvantum/kvantum.kvconfig" = mkIf (cfg.settings != { }) {
        source = kvconfigFormat.generate "kvantum-config" cfg.settings;
      };
    };
  };
}
