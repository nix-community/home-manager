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

  /*
    Builds the state-version migration values for options whose defaults change
    based on `home.stateVersion`.

    In the default mode, this returns `default` and `defaultText` for direct use
    in `mkOption`, and emits the migration warning with `lib.warn` when the
    legacy branch is active.

    In deferred mode (`deferWarningToConfig = true`), this keeps `default`
    pinned to `current.value` and additionally returns:
      - `warning`: the warning text to add to `config.warnings`
      - `shouldWarn`: whether the warning should be emitted
      - `effectiveDefault`: the state-version-selected value
      - `optionUsesDefaultPriority`: whether the option is still at its module default priority

    Deferred mode is intended for merged attrset options where warning from the
    option default itself is too early to be silenced reliably by explicit user
    assignments. It requires passing both `config` and `options`.

    Direct example:
      let
        stateVersionDefault = lib.hm.deprecations.mkStateVersionOptionDefault {
          inherit (config.home) stateVersion;
          since = "26.05";
          optionPath = [ "programs" "example" "foo" ];
          legacy.value = "old";
          current.value = "new";
        };
      in
      lib.mkOption {
        inherit (stateVersionDefault) default defaultText;
      };

    Deferred-warning example:
      let
        stateVersionDefault = lib.hm.deprecations.mkStateVersionOptionDefault {
          inherit (config.home) stateVersion;
          inherit config options;
          since = "26.05";
          optionPath = [ "programs" "example" "settings" ];
          legacy.value = { FOO = "legacy"; };
          current.value = { };
          deferWarningToConfig = true;
        };
      in {
        options.programs.example.settings = lib.mkOption {
          default = { };
          inherit (stateVersionDefault) defaultText;
        };

        config.warnings = lib.optional stateVersionDefault.shouldWarn stateVersionDefault.warning;
      };
  */
  mkStateVersionOptionDefault =
    {
      stateVersion,
      since,
      optionPath,
      legacy,
      current,
      extraWarning ? "",
      config ? null,
      options ? null,
      warningPriority ? (lib.mkOptionDefault { }).priority,
      shouldWarn ? null,
      deferWarningToConfig ? false,
    }:
    let
      option = lib.showOption optionPath;
      legacyText = legacy.text or (lib.generators.toPretty { } legacy.value);
      currentText = current.text or (lib.generators.toPretty { } current.value);
      warning = ''
        The default value of `${option}` has changed from `${legacyText}` to `${currentText}`.
        You are currently using the legacy default (`${legacyText}`) because `home.stateVersion` is less than "${since}".
        To silence this warning and keep legacy behavior, set:
          ${option} = ${legacyText};
        To adopt the new default behavior, set:
          ${option} = ${currentText};
      ''
      + lib.optionalString (extraWarning != "") ("\n" + extraWarning);
      canDeferWarning = config != null && options != null;
      optionInfo = lib.optionalAttrs canDeferWarning (lib.getAttrFromPath optionPath options);
      optionUsesDefaultPriority = canDeferWarning && optionInfo.highestPrio >= warningPriority;

      usingLegacyBranch = lib.versionOlder stateVersion since;
    in
    assert lib.assertMsg (!deferWarningToConfig || canDeferWarning) ''
      `lib.hm.deprecations.mkStateVersionOptionDefault` requires both `config` and `options`
      when `deferWarningToConfig = true`.
    '';
    {
      default =
        if usingLegacyBranch && !deferWarningToConfig then lib.warn warning legacy.value else current.value;
      defaultText = lib.literalExpression ''
        if lib.versionAtLeast config.home.stateVersion "${since}" then ${currentText} else ${legacyText}
      '';
      effectiveDefault = if usingLegacyBranch then legacy.value else current.value;
      inherit warning optionUsesDefaultPriority;
      shouldWarn =
        deferWarningToConfig
        && usingLegacyBranch
        && (
          if lib.isFunction shouldWarn then
            shouldWarn { inherit optionInfo optionUsesDefaultPriority; }
          else
            optionUsesDefaultPriority
        );
    };
}
