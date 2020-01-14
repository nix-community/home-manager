{ lib, dag ? import ./dag.nix { inherit lib; } }:

with lib;

let

  hmLib = import ./default.nix { inherit lib; };
  typesDag = import ./types-dag.nix { inherit dag lib; };

in

{

  inherit (typesDag) dagOf listOrDagOf;

  selectorFunction = mkOptionType {
    name = "selectorFunction";
    description =
      "Function that takes an attribute set and returns a list"
      + " containing a selection of the values of the input set";
    check = isFunction;
    merge = _loc: defs:
      as: concatMap (select: select as) (getValues defs);
  };

  overlayFunction = mkOptionType {
    name = "overlayFunction";
    description =
      "An overlay function, takes self and super and returns"
      + " an attribute set overriding the desired attributes.";
    check = isFunction;
    merge = _loc: defs:
      self: super:
        foldl' (res: def: mergeAttrs res (def.value self super)) {} defs;
  };

}
