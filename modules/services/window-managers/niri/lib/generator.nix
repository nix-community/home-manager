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
    concatMap
    nameValuePair
    ;

  inherit (lib.hm.generators) toKDL;

  # converts camelCase to kebab-case
  toKebabCase =
    str:
    let
      parts = splitStringBy (
        prev: curr: builtins.elem curr upperChars && builtins.elem prev lowerChars
      ) true str;
    in
    concatMapStringsSep "-" toLower parts;

  # filters out values of null, also traversing '_children' list attributes.
  # to preserve null values, an attribute named '_preserve_null' can be placed inside an attrset.
  # 'a = { b = null; _preserve_null = {}; };' will preserve 'a.b = null;'.
  filterStep =
    set:
    pipe set [
      builtins.attrNames
      (concatMap (
        name:
        let
          v = set.${name};
        in
        if (v != null || builtins.hasAttr "_preserve_null" set) && name != "_preserve_null" then
          [
            (nameValuePair name (
              if builtins.isAttrs v then
                filterStep v
              else
                (if builtins.isList v && name == "_children" then map filterStep v else v)
            ))
          ]
        else
          [ ]
      ))
      builtins.listToAttrs
    ];

  # rename everything to kebab case
  renameStep =
    set:
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
    recurse set;
in
pipe cfg [
  filterStep
  renameStep
  (toKDL { })
]
