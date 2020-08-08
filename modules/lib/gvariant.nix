# A partial and basic implementation of GVariant formatted strings.
#
# Note, this API is not considered fully stable and it might therefore
# change in backwards incompatible ways without prior notice.

{ lib }:

with lib;

let

  mkPrimitive = t: v: {
    _type = "gvariant";
    type = t;
    value = v;
    __toString = self: "@${self.type} ${toString self.value}";
  };

  type = {
    arrayOf = t: "a${t}";
    maybeOf = t: "m${t}";
    tupleOf = ts: "(${concatStrings ts})";
    string = "s";
    boolean = "b";
    uchar = "y";
    int16 = "n";
    uint16 = "q";
    int32 = "i";
    uint32 = "u";
    int64 = "x";
    uint64 = "t";
    double = "d";
  };

  # Returns the GVariant type of a given Nix value. If no type can be
  # found for the value then the empty string is returned.
  typeOf = v:
    with type;
    if builtins.isBool v then
      boolean
    else if builtins.isInt v then
      int32
    else if builtins.isFloat v then
      double
    else if builtins.isString v then
      string
    else if builtins.isList v then
      let elemType = elemTypeOf v;
      in if elemType == "" then "" else arrayOf elemType
    else if builtins.isAttrs v && v ? type then
      v.type
    else
      "";

  elemTypeOf = vs:
    if builtins.isList vs then
      if vs == [ ] then "" else typeOf (head vs)
    else
      "";

  mkMaybe = elemType: elem:
    mkPrimitive (type.maybeOf elemType) elem // {
      __toString = self:
        if self.value == null then
          "@${self.type} nothing"
        else
          "just ${toString self.value}";
    };

in rec {

  inherit type typeOf;

  isArray = hasPrefix "a";
  isMaybe = hasPrefix "m";
  isTuple = hasPrefix "(";

  # Returns the GVariant value that most closely matches the given Nix
  # value. If no GVariant value can be found then `null` is returned.
  #
  # No support for dictionaries, maybe types, or variants.
  mkValue = v:
    if builtins.isBool v then
      mkBoolean v
    else if builtins.isInt v then
      mkInt32 v
    else if builtins.isFloat v then
      mkDouble v
    else if builtins.isString v then
      mkString v
    else if builtins.isList v then
      if v == [ ] then mkArray type.string [ ] else mkArray (elemTypeOf v) v
    else if builtins.isAttrs v && (v._type or "") == "gvariant" then
      v
    else
      null;

  mkArray = elemType: elems:
    mkPrimitive (type.arrayOf elemType) (map mkValue elems) // {
      __toString = self:
        "@${self.type} [${concatMapStringsSep "," toString self.value}]";
    };

  mkEmptyArray = elemType: mkArray elemType [ ];

  mkNothing = elemType: mkMaybe elemType null;

  mkJust = elem: let gvarElem = mkValue elem; in mkMaybe gvarElem.type gvarElem;

  mkTuple = elems:
    let
      gvarElems = map mkValue elems;
      tupleType = type.tupleOf (map (e: e.type) gvarElems);
    in mkPrimitive tupleType gvarElems // {
      __toString = self:
        "@${self.type} (${concatMapStringsSep "," toString self.value})";
    };

  mkBoolean = v:
    mkPrimitive type.boolean v // {
      __toString = self: if self.value then "true" else "false";
    };

  mkString = v:
    mkPrimitive type.string v // {
      __toString = self: "'${escape [ "'" "\\" ] self.value}'";
    };

  mkObjectpath = v:
    mkPrimitive type.string v // {
      __toString = self: "objectpath '${escape [ "'" ] self.value}'";
    };

  mkUchar = mkPrimitive type.uchar;

  mkInt16 = mkPrimitive type.int16;

  mkUint16 = mkPrimitive type.uint16;

  mkInt32 = v:
    mkPrimitive type.int32 v // {
      __toString = self: toString self.value;
    };

  mkUint32 = mkPrimitive type.uint32;

  mkInt64 = mkPrimitive type.int64;

  mkUint64 = mkPrimitive type.uint64;

  mkDouble = v:
    mkPrimitive type.double v // {
      __toString = self: toString self.value;
    };

}
