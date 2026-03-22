{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    concatMapStringsSep
    filterAttrs
    generators
    literalExpression
    mapAttrs
    mapAttrs'
    mkIf
    mkOption
    nameValuePair
    stringLength
    substring
    toList
    toUpper
    types
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
  options.qt.kvantum = {
    settings = mkOption {
      type = types.submodule {
        freeformType = types.attrsOf kvconfigSection;

        options = {
          general = mkOption {
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

          applications = mkOption {
            type = with types; attrsOf (either str (listOf str));
            apply = attrs: mapAttrs (_: v: toList v) attrs;
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

              Themes set here will override {option}`qt.kvantum.settings.general.theme`
              for their specific applications.
            '';
          };
        };
      };
      default = { };
      apply =
        attrs:
        mapAttrs' (
          n: v: # general -> General
          nameValuePair (toUpper (substring 0 1 n) + (substring 1 (stringLength n) n)) v
        ) (filterAttrs (_: v: v != { }) attrs);
      example = {
        general = {
          theme = "KvAdapta";
        };
        applications = {
          KvArc = [
            "app1"
            "app2"
          ];
          KvFlat = [ "app3" ];
        };
        somethingElse = {
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

  config = {
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
