{ lib }:

let
  inherit (lib)
    concatMapStringsSep escape replaceStrings boolToString floatToString
    concatStringsSep mapAttrsToList;

  inherit (builtins) mapAttrs;

  mkPrimitive = t: v: {
    _type = "godotData";
    type = t;
    value = v;
    __toString = self: toString self.value;
  };

in rec {
  isGodotData = v: v._type or "" == "godotData";

  mkValue = v:
    if builtins.isBool v then
      mkBool v
    else if builtins.isInt v then
      mkInt v
    else if builtins.isFloat v then
      mkFloat v
    else if builtins.isString v then
      mkString v
    else if builtins.isList v then
      mkList v
    else if builtins.isAttrs v && (v._type or "") == "godotData" then
      v
    else if builtins.isAttrs v then
      mkAttrs v
    else
      null;

  mkList = elems:
    mkPrimitive "list" (map mkValue elems) // {
      __toString = self: "[${concatMapStringsSep ", " toString self.value}]";
    };

  mkAttrs = attrs:
    mkPrimitive "attrs" (mapAttrs (name: mkValue) attrs) // {
      __toString = self:
        "{${
          concatStringsSep ", "
          (mapAttrsToList (name: value: "${mkString name}: ${value}")
            self.value)
        }}";
    };

  mkBool = v:
    mkPrimitive "bool" v // {
      __toString = self: boolToString self.value;
    };

  mkString = v:
    let
      sanitize = s: replaceStrings [ "\n" ] [ "\\n" ] (escape [ ''"'' "\\" ] s);
    in mkPrimitive "string" v // {
      __toString = self: ''"${sanitize self.value}"'';
    };

  mkInt = mkPrimitive "int";

  mkFloat = mkPrimitive "float";

  mkCall = name: args:
    mkPrimitive "call" { inherit name args; } // {
      __toString = self:
        "${self.value.name}(${
          concatMapStringsSep ", " toString self.value.args
        })";
    };
}
