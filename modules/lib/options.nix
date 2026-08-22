{ lib }:

{
  /**
    Locate the files that define attribute `name` of an `attrsOf` option.
    Standard definition wrappers (mkMerge, mkIf, mkOverride, mkOrder, and
    functions built on them such as mkForce or mkBefore) are unwrapped, and
    false mkIf branches are excluded, so wrapped definitions are attributed
    to the correct file. Definitions with an unrecognized wrapper type are
    skipped.

    # Type

    ```
    attrDefinitionFiles :: Option -> String -> [ String ]
    ```
  */
  attrDefinitionFiles =
    option: name:
    let
      unwrap =
        value:
        let
          t = value._type or "";
        in
        if t == "merge" then
          lib.concatMap unwrap value.contents
        else if t == "if" then
          lib.optionals value.condition (unwrap value.content)
        else if t == "override" || t == "order" then
          unwrap value.content
        else
          [ value ];
      defines = def: lib.any (value: lib.isAttrs value && value ? ${name}) (unwrap def.value);
    in
    map (def: def.file) (lib.filter defines option.definitionsWithLocations);
}
