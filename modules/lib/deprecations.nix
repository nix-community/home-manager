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
}
