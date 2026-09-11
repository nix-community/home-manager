{ lib }:

{
  /**
    Return the files whose surviving definitions contribute to attribute
    `name` of an `attrsOf` or `lazyAttrsOf` option. The element type's
    conditions, priorities, ordering, and definition locations are preserved.

    # Type

    ```
    attrDefinitionFiles :: Option -> String -> [ String ]
    ```
  */
  attrDefinitionFiles =
    option: name:
    let
      pushDownDefinitionProperties =
        value:
        let
          type = value._type or "";
          push = wrap: lib.map (lib.mapAttrs (_: wrap));
        in
        if type == "merge" then
          lib.concatMap pushDownDefinitionProperties value.contents
        else if type == "if" then
          push (lib.mkIf value.condition) (pushDownDefinitionProperties value.content)
        else if type == "override" then
          push (lib.mkOverride value.priority) (pushDownDefinitionProperties value.content)
        else if type == "order" then
          push (lib.mkOrder value.priority) (pushDownDefinitionProperties value.content)
        else if type == "definition" then
          push (attributeValue: value // { value = attributeValue; }) (
            pushDownDefinitionProperties value.value
          )
        else
          [ value ];
      definitionsByName = lib.zipAttrs (
        lib.concatMap (
          definition:
          lib.concatMap (
            value:
            lib.mapAttrsToList (name: value: {
              ${name} = definition // {
                inherit value;
              };
            }) value
          ) (pushDownDefinitionProperties definition.value)
        ) option.definitionsWithLocations
      );
      merged = lib.modules.mergeDefinitions (option.loc ++ [ name ]) option.type.nestedTypes.elemType (
        definitionsByName.${name} or [ ]
      );
    in
    assert lib.elem option.type.name [
      "attrsOf"
      "lazyAttrsOf"
    ];
    lib.unique (map (definition: definition.file) merged.defsFinal);
}
