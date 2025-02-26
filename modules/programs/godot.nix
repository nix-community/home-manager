{ config, lib, pkgs, ... }:
let
  inherit (lib)
    literalExpression mkEnableOption mkOption mkIf types hm mapAttrsToList
    splitString mkOptionDefault singleton concatMapStringsSep mkMerge mapAttrs'
    nameValuePair;

  inherit (hm.godot) mkValue;

  inherit (builtins) concatStringsSep typeOf toString head;

  cfg = config.programs.godot;

  primitiveType = with types; oneOf [ str int float bool attrs ];

  primitiveTypeOrAttrs = with types;
    either primitiveType (attrsOf primitiveType);

  composedType = with types;
    either primitiveTypeOrAttrs (listOf primitiveTypeOrAttrs);

  dataType = with types; coercedTo composedType mkValue attrs;

  # See https://docs.godotengine.org/en/latest/contributing/development/file_formats/tscn.html.
  genResources = concatMapStringsSep "\n\n" genResource;

  genResource = { type, attributes ? { }, data ? { } }:
    concatStringsSep "\n" ([
      (genHeader { inherit type attributes; })
    ] ++ (mapAttrsToList (name: value: "${name} = ${value}") data));

  genHeader = { type, attributes }:
    "[${
      concatStringsSep " " ([ type ]
        ++ (mapAttrsToList (name: val: "${name}=${mkValue val}") attributes))
    }]";

in {
  meta.maintainers = [ hm.maintainers.bricked ];

  options.programs.godot = {
    enable = mkEnableOption "Godot";

    package = lib.mkPackageOption pkgs "godot_4" { };

    version = lib.mkOption {
      type = types.str;
      description = ''
        Semantic version of the Godot package.
      '';
      internal = true;
    };

    settings = mkOption {
      type = with types; nullOr (attrsOf dataType);
      description = ''
        Attribute set of godot editor settings.

        For a list of available options see https://docs.godotengine.org/en/stable/classes/class_editorsettings.html.

        Primitive values, lists and attrs work as expected. For function calls, 'lib.hm.godot.mkCall name args' is used.
      '';
      example = literalExpression ''
        {
          "resource_local_to_scene" = false;
          "interface/editor/editor_language" = "en";
          "interface/editor/main_font_size" = 14;
          "interface/theme/accent_color" = lib.hm.godot.mkCall "Color" [ 0.5, 0.5, 1.0, 1.0 ];
          "text_editor/theme/color_theme" = "Dracula";
        }'';
    };

    textThemes = mkOption {
      type = with types;
        attrsOf (submodule ({ name, ... }: {
          options = {
            name = mkOption {
              type = types.str;
              description = ''
                The name of the text editor theme.
              '';
              example = "Dracula";
              default = name;
            };

            settings = mkOption {
              type = with types; attrsOf dataType;
              description = ''
                Attribute set of text editor theme data.
              '';
              example = {
                text_color = "cdd6f4ff";
                number_color = "fab387ff";
              };
            };
          };
        }));
      description = ''
        Attribute set of text editor themes.

        The default text editor theme can be defined using the "text_editor/theme/color_theme" setting.
      '';
      default = { };
    };
  };

  config = mkIf cfg.enable {
    programs.godot.version =
      mkOptionDefault (head (splitString "-" cfg.package.version));

    home.packages = [ cfg.package ];

    xdg.configFile = {
      "godot/editor_settings-${cfg.version}.tres".text =
        mkIf (cfg.settings != null) (genResources [
          {
            type = "gd_resource";
            attributes = {
              type = "EditorSettings";
              format = 3;
            };
          }

          {
            type = "resource";
            data = cfg.settings;
          }
        ]);
    } // mapAttrs' (name: theme:
      nameValuePair "godot/text_editor_themes/${theme.name}.tet" {
        text = genResource {
          type = "color_theme";
          data = theme.settings;
        };
      }) cfg.textThemes;
  };
}
