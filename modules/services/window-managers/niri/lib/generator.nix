lib: cfg:
let
  inherit (lib)
    splitStringBy
    upperChars
    concatMapStringsSep
    toLower
    lowerChars
    flip
    pipe
    mapAttrsToList
    ;

  inherit (lib.generators) toKDL;

  # converts camelCase to kebab-case
  toKebabCase =
    str:
    let
      parts = splitStringBy (
        prev: curr: builtins.elem curr upperChars && builtins.elem prev lowerChars
      ) true str;
    in
    concatMapStringsSep "-" toLower parts;

  # filters out values of null, also traversing '_children' list attributes
  filterStep =
    cfg:
    let
      attrFilterPass = lib.attrsets.filterAttrsRecursive (_: v: v != null) cfg;
      listFilterPass = lib.attrsets.mapAttrsRecursive (
        path: value: if (lib.last path) == "_children" then map filterStep value else value
      ) attrFilterPass;
    in
    listFilterPass;

  # rename everything to kebab case
  renameStep =
    cfg:
    let
      recurse = flip pipe [
        (mapAttrsToList (
          n: v: {
            name =
              # sometimes a name needs to be preserved
              if (builtins.typeOf v) == "set" && builtins.hasAttr "_preserve_name" v then n else toKebabCase n;
            value =
              if (builtins.typeOf v) == "set" then
                # the tag shouldn't be included in the generated output
                recurse (removeAttrs v [ "_preserve_name" ])
              else if (builtins.typeOf v) == "list" && n == "_children" then
                (map recurse v)
              else
                v;
          }
        ))
        builtins.listToAttrs
      ];
    in
    recurse cfg;
in
pipe cfg [
  filterStep
  renameStep
  (toKDL { })
]
