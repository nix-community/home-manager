{ lib, gvariant ? import ./gvariant.nix { inherit lib; } }:

let
  inherit (lib)
    all concatMap foldl' getFiles getValues head isFunction literalExpression
    mergeAttrs mergeDefaultOption mergeOneOption mergeOptions mkOption
    mkOptionType showFiles showOption types;

  typesDag = import ./types-dag.nix { inherit lib; };

  # Needed since the type is called gvariant and its merge attribute
  # must refer back to the type.
  gvar = gvariant;

in rec {

  inherit (typesDag) dagOf;

  selectorFunction = mkOptionType {
    name = "selectorFunction";
    description = "Function that takes an attribute set and returns a list"
      + " containing a selection of the values of the input set";
    check = isFunction;
    merge = _loc: defs: as: concatMap (select: select as) (getValues defs);
  };

  overlayFunction = mkOptionType {
    name = "overlayFunction";
    description = "An overlay function, takes self and super and returns"
      + " an attribute set overriding the desired attributes.";
    check = isFunction;
    merge = _loc: defs: self: super:
      foldl' (res: def: mergeAttrs res (def.value self super)) { } defs;
  };

  fontType = types.submodule {
    options = {
      package = mkOption {
        type = types.nullOr types.package;
        default = null;
        example = literalExpression "pkgs.dejavu_fonts";
        description = ''
          Package providing the font. This package will be installed
          to your profile. If `null` then the font
          is assumed to already be available in your profile.
        '';
      };

      name = mkOption {
        type = types.str;
        example = "DejaVu Sans";
        description = ''
          The family name of the font within the package.
        '';
      };

      size = mkOption {
        type = types.nullOr types.number;
        default = null;
        example = "8";
        description = ''
          The size of the font.
        '';
      };
    };
  };

  gvariant = mkOptionType rec {
    name = "gvariant";
    description = "GVariant value";
    check = v: gvar.mkValue v != null;
    merge = loc: defs:
      let
        vdefs = map (d:
          d // {
            value =
              if gvar.isGVariant d.value then d.value else gvar.mkValue d.value;
          }) defs;
        vals = map (d: d.value) vdefs;
        defTypes = map (x: x.type) vals;
        sameOrNull = x: y: if x == y then y else null;
        # A bit naive to just check the first entry…
        sharedDefType = foldl' sameOrNull (head defTypes) defTypes;
        allChecked = all (x: check x) vals;
      in if sharedDefType == null then
        throw ("Cannot merge definitions of `${showOption loc}' with"
          + " mismatched GVariant types given in"
          + " ${showFiles (getFiles defs)}.")
      else if gvar.isArray sharedDefType && allChecked then
        gvar.mkValue ((types.listOf gvariant).merge loc
          (map (d: d // { value = d.value.value; }) vdefs)) // {
            type = sharedDefType;
          }
      else if gvar.isTuple sharedDefType && allChecked then
        mergeOneOption loc defs
      else if gvar.isMaybe sharedDefType && allChecked then
        mergeOneOption loc defs
      else if gvar.isDictionaryEntry sharedDefType && allChecked then
        mergeOneOption loc defs
      else if gvar.type.variant == sharedDefType && allChecked then
        mergeOneOption loc defs
      else if gvar.type.string == sharedDefType && allChecked then
        types.str.merge loc defs
      else if gvar.type.double == sharedDefType && allChecked then
        types.float.merge loc defs
      else
        mergeDefaultOption loc defs;
  };

  nushellValue = let
    valueType = types.nullOr (types.oneOf [
      (lib.mkOptionType {
        name = "nushell";
        description = "Nushell inline value";
        descriptionClass = "name";
        check = lib.isType "nushell-inline";
      })
      types.bool
      types.int
      types.float
      types.str
      types.path
      (types.attrsOf valueType // {
        description = "attribute set of Nushell values";
        descriptionClass = "name";
      })
      (types.listOf valueType // {
        description = "list of Nushell values";
        descriptionClass = "name";
      })
    ]);
  in valueType;
}
