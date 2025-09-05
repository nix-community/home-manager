{ lib }:
{
  /*
    Returns a function that maps
      [
        "someOption"
        ["fooBar" "someSubOption"]
        { old = "someOtherOption"; new = ["foo_bar" "some_other_option"]}
      ]

    to
      [
        (lib.mkRenamedOptionModule
          (oldPath ++ ["someOption"])
          (newPath ++ ["some_option"])
        )
        (lib.mkRenamedOptionModule
          (oldPath ++ ["fooBar" "someSubOption"])
          (newPath ++ ["foo_bar" "some_sub_option"])
        )
        (lib.mkRenamedOptionModule
          (oldPath ++ ["someOtherOption"])
          (newPath ++ ["foo_bar" "some_other_option"])
        )
      ]

    The transform parameter is a function that takes a string and returns a string.
    It is applied to each element of the old option path to generate the new option path.
    Defaults to lib.hm.strings.toSnakeCase.
  */
  mkSettingsRenamedOptionModules =
    oldPrefix: newPrefix:
    {
      transform ? lib.hm.strings.toSnakeCase,
    }:
    map (
      spec:
      let
        finalSpec =
          if lib.isAttrs spec then
            lib.mapAttrs (_: lib.toList) spec
          else
            {
              old = lib.toList spec;
              new = map transform finalSpec.old;
            };
      in
      lib.mkRenamedOptionModule (oldPrefix ++ finalSpec.old) (newPrefix ++ finalSpec.new)
    );

  /*
    Recursively transforms attribute set keys, issuing a warning for each transformation.

    The function takes an attribute set with the following keys:
     - pred: (str -> bool) Predicate to detect which keys to transform.
     - transform: (str -> str) Function to transform the key.
     - ignore: (list of str) Optional. A list of keys to never transform,
       even if they match `pred`.

    Example:
      let
        # Renames camelCase keys to snake_case.
        migrateCamelCase = lib.hm.deprecations.remapAttrsRecursive {
          # A key needs migration if it contains a lowercase letter followed by an uppercase one.
          pred = key: builtins.match ".*[a-z][A-Z].*" key != null;
          # The transformation to apply.
          transform = lib.hm.strings.toSnakeCase;
          # Keys we will not rename
          ignore = [ "allowThisOne" ];
        };
      in
        migrateCamelCase "programs.mymodule.settings" {
          someSetting = 1;      # will be renamed
          allowThisOne = 2;     # will be ignored
        }
        # => { some_setting = 1; allowThisOne = 2; }
  */
  remapAttrsRecursive =
    {
      pred,
      transform,
      ignore ? [ ],
    }:
    let
      migrate =
        path: value:
        if builtins.isAttrs value then
          lib.mapAttrs' (
            name: val:
            let
              newName = if pred name && !(builtins.elem name ignore) then transform name else name;

              warnOrId =
                if newName != name then
                  lib.warn "home-manager: The setting '${name}' in '${path}' was automatically renamed to '${newName}'. Please update your configuration."
                else
                  x: x;
            in
            warnOrId {
              name = newName;
              value = migrate "${path}.${name}" val;
            }
          ) value
        else if builtins.isList value then
          lib.imap0 (index: val: migrate "${path}.[${toString index}]" val) value
        else
          value;
    in
    pathStr: attrs: migrate pathStr attrs;
}
