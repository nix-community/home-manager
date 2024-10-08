{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit
    (lib)
    filterAttrs
    concatStrings
    concatStringsSep
    mapAttrsToList
    concatLists
    foldlAttrs
    concatMapAttrs
    mapAttrs'
    nameValuePair
    boolToString
    ;
  inherit (builtins) typeOf toString stringLength;

  # build up serialisation machinery from here for various types

  # list -> array
  array = a: "[${concatStringsSep "," a}]";
  # attrset -> hashmap
  _assoc = a: mapAttrsToList (name: val: "${name}: ${val}") a;
  assoc = a: ''
    {
        ${
      concatStringsSep ''
        ,
      '' (concatLists (map _assoc a))
    }
        }'';
  # attrset -> struct
  _struct_kv = k: v:
    if v == null
    then ""
    else (concatStringsSep ":" [k (serialise.${typeOf v} v)]);
  _struct_concat = s:
    foldlAttrs (acc: k: v:
      if stringLength acc > 0
      then concatStringsSep ", " [acc (_struct_kv k v)]
      else _struct_kv k v) ""
    s;
  _struct_filt = s: _struct_concat (filterAttrs (k: v: v != null) s);
  struct = s: "(${_struct_filt s})";
  toQuotedString = s: ''"${toString s}"'';

  # make an attrset for struct serialisation
  serialise = {
    int = toString;
    float = toString;
    bool = boolToString;
    string = toString;
    path = toString;
    null = toString;
    set = struct;
    list = array;
  };

  # define the key for a keybind
  defineBinding = binding:
    struct {
      inherit (binding) modifiers;
      key =
        if isNull binding.key
        then null
        else toQuotedString binding.key;
    };

  # map keybinding from list of attrset to hashmap of (mod,key): action
  _mapBindings = bindings:
    map (inner: {
      "${defineBinding inner}" = maybeToString (checkAction inner.action);
    })
    bindings;
  mapBindings = bindings: assoc (_mapBindings bindings);

  # check a keybinding's action
  # escape with quotes if it's a Spawn action
  checkAction = a:
    if typeOf a == "set" && a.type == "Spawn"
    then {
      inherit (a) type;
      data = toQuotedString a.data;
    }
    else a;

  maybeToString = s:
    if typeOf s == "set"
    then concatStrings [s.type "(" (toString s.data) ")"]
    else s;

  mapCosmicSettings = application: options:
    mapAttrs' (k: v:
      nameValuePair "cosmic/${application}/v${options.version}/${k}" {
        enable = true;
        text = serialise.${typeOf v} v;
      })
    options.option;

  cfg = config.programs.cosmic;
in {
  meta.maintainers = [hm.maintainers.atagen];
  options.programs.cosmic = {
    enable = with lib; mkEnableOption "COSMIC DE";

    defaultKeybindings = with lib;
      mkOption {
        default = true;
        type = types.bool;
        description = "Whether to enable the default COSMIC keybindings.";
      };

    keybindings = with lib;
      mkOption {
        default = [];
        type = with types;
          listOf (submodule {
            options = {
              modifiers = mkOption {
                type = listOf str;
                default = [];
              };
              key = mkOption {
                type = nullOr str;
                default = null;
              };
              action = mkOption {
                type = either str (submodule {
                  options = {
                    type = mkOption {type = str;};
                    data = mkOption {
                      type = oneOf [str int];
                      default = "";
                    };
                  };
                });
              };
            };
          });
        description = ''
          A set of keybindings and actions for the COSMIC DE.
          The list of actions and possible values can be found presently at: https://github.com/pop-os/cosmic-settings-daemon/blob/master/config/src/shortcuts/action.rs
        '';
        example = literalExpression ''
          [
            # Key + mod + Spawn action
            {
              key = "Return";
              modifiers = ["Super"];
              action = {
                type = "Spawn";
                data = "kitty";
              };
            }
            # Only mod - activates if no key is pressed with the modifier
            {
              modifiers = ["Super"];
              action = {
                type = "Spawn";
                data = "wofi";
              }
            }
            # Key only and plain action
            {
              key = "G";
              action = "ToggleWindowFloating";
            }
          ]
        '';
      };

    settings = with lib;
      mkOption {
        default = {};
        type = with types;
          attrsOf (submodule {
            options = {
              version = mkOption {
                type = str;
                default = "1";
              };
              option = mkOption {type = attrsOf anything;};
            };
          });
        description = ''
          An attrset of explicit settings for COSMIC apps, using their full config path.
        '';
        example = literalExpression ''
          {
            "com.system76.CosmicPanel.Dock" = {
              option.opacity = 0.8;
            };
          };
        '';
      };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile =
      {
        "cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom".text =
          (lib.mkIf cfg.keybindings != []) mapBindings cfg.keybindings;
        "cosmic/com.system76.CosmicSettings.Shortcuts/v1/defaults" = {
          text = "{}";
          enable = !cfg.defaultKeybindings;
        };
      }
      // concatMapAttrs
      (application: options: mapCosmicSettings application options)
      cfg.settings;
  };
}
