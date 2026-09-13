{ lib }:
let
  mkRenamedOptionModuleWith =
    {
      from,
      to,
      value,
      condition,
    }:
    args@{ options, ... }:
    lib.doRename
      {
        inherit from to condition;
        visible = false;
        warn = true;
        use = lib.id;
        # The forwarded definitions already carry their intended priorities.
        withPriority = false;
      }
      (
        args
        // {
          options = lib.recursiveUpdate options (lib.setAttrByPath from { definitions = [ value ]; });
        }
      );
in
{
  /**
    Build a warning for a deprecated option value shape.

    # Inputs

    `option`

    : Option path whose value shape is deprecated.

    `old`

    : Description of the deprecated value shape.

    `replacement`

    : Replacement option or value description.

    `details` (string; optional)

    : Additional warning text. Defaults to `""`.

    # Type

    ```
    mkDeprecatedOptionValueWarning :: { option :: [ String ]; old :: String; replacement :: String; details ? String; } -> String
    ```

    # Examples
    :::{.example}
    ## `lib.hm.deprecations.mkDeprecatedOptionValueWarning` usage example

    ```nix
    lib.hm.deprecations.mkDeprecatedOptionValueWarning {
      option = [ "programs" "example" "settings" ];
      old = "a list";
      replacement = "`programs.example.settings.items`";
    }
    => Using `programs.example.settings` as a list is deprecated and will be
       removed in a future release. Please use `programs.example.settings.items`
       instead.
    ```

    :::
  */
  mkDeprecatedOptionValueWarning =
    {
      option,
      old,
      replacement,
      details ? "",
    }:
    ''
      Using `${lib.showOption option}` as ${old} is deprecated and will be
      removed in a future release. Please use ${replacement} instead.
    ''
    + lib.optionalString (details != "") ''

      ${details}
    '';

  /**
    Build a warning for a renamed option value.

    # Inputs

    `option`

    : Option path whose value is deprecated.

    `old`

    : Deprecated value description.

    `replacement`

    : Replacement value description.

    # Type

    ```
    mkDeprecatedOptionValueRenameWarning :: { option :: [ String ]; old :: String; replacement :: String; } -> String
    ```

    # Examples
    :::{.example}
    ## `lib.hm.deprecations.mkDeprecatedOptionValueRenameWarning` usage example

    ```nix
    lib.hm.deprecations.mkDeprecatedOptionValueRenameWarning {
      option = [ "programs" "example" "mode" ];
      old = "basic";
      replacement = "standard";
    }
    => The value basic for `programs.example.mode` is deprecated and will be
       removed in a future release. Please use standard instead.
    ```

    :::
  */
  mkDeprecatedOptionValueRenameWarning =
    {
      option,
      old,
      replacement,
    }:
    ''
      The value ${old} for `${lib.showOption option}` is deprecated and will be
      removed in a future release. Please use ${replacement} instead.
    '';

  /**
    Return a function that creates renamed option modules from path specifications.

    The function maps old paths under `oldPrefix` to new paths under `newPrefix`.
    A string or list specifies one old path; an attribute set specifies both
    `old` and `new` paths. Only implicit new paths use `transform`.
    Set `preserveOrder` when definitions must retain their `mkBefore` and
    `mkAfter` ordering.

    # Inputs

    `oldPrefix`

    : Prefix for old option paths.

    `newPrefix`

    : Prefix for new option paths.

    `options`

    : Function options.

      `preserveOrder` (boolean; optional)
      : Preserve definition ordering. Defaults to `false`.

      `transform` (function; optional)
      : Transform each implicit new path element. Defaults to `lib.hm.strings.toSnakeCase`.

    `specs`

    : List of strings, path lists, or attribute sets with explicit `old` and `new` paths.

    # Type

    ```
    mkSettingsRenamedOptionModules :: [ String ] -> [ String ] -> AttrSet -> [ Any ] -> [ Function ]
    ```

    # Examples
    :::{.example}
    ## `lib.hm.deprecations.mkSettingsRenamedOptionModules` usage example

    ```nix
    lib.hm.deprecations.mkSettingsRenamedOptionModules [ "programs" ] [ "settings" ] { }
    [
      "someOption"
      [ "fooBar" "someSubOption" ]
      { old = "someOtherOption"; new = [ "foo_bar" "some_other_option" ]; }
    ]
    =>
    [
      (lib.mkRenamedOptionModule
        [ "programs" "someOption" ]
        [ "settings" "some_option" ]
      )
      (lib.mkRenamedOptionModule
        [ "programs" "fooBar" "someSubOption" ]
        [ "settings" "foo_bar" "some_sub_option" ]
      )
      (lib.mkRenamedOptionModule
        [ "programs" "someOtherOption" ]
        [ "settings" "foo_bar" "some_other_option" ]
      )
    ]
    ```

    :::
  */
  mkSettingsRenamedOptionModules =
    oldPrefix: newPrefix:
    {
      preserveOrder ? false,
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
        from = oldPrefix ++ finalSpec.old;
        to = newPrefix ++ finalSpec.new;
      in
      if !preserveOrder then
        lib.mkRenamedOptionModule from to
      else
        args@{ options, ... }:
        let
          option = lib.getAttrFromPath from options;
          forwardDefinition =
            definition:
            lib.modules.mkDefinition {
              inherit (definition) file;
              value = lib.mkOverride option.highestPrio (
                lib.mkOrder (definition.priority or lib.modules.defaultOrderPriority) definition.value
              );
            };
        in
        mkRenamedOptionModuleWith {
          inherit from to;
          condition = option.isDefined;
          value = lib.mkMerge (map forwardDefinition option.definitionsWithLocations);
        } args
    );

  /**
    Migrate a default-empty attribute-set overlay to freeform settings.

    Returns an attribute set with `module`, which declares and forwards the alias,
    and `keys`, the effective immediate keys. Callers can use `keys` to suppress
    modeled values formerly overwritten by the overlay. Root priorities apply
    only to supplied keys. Explicit key priorities and nested definitions remain
    intact. Keys with only disabled conditions are absent; null and empty values
    still count as supplied. Sources weaker than the historical empty option
    default are ignored.

    Remove the old option declaration and its default when importing `module`.
    Retaining the default can warn even when the user has not set the old option.

    # Inputs

    `options`

    : Current module option definitions.

    `from`

    : Old option path.

    `to`

    : New option path.

    # Type

    ```
    mkSettingsOverlay :: { options :: AttrSet; from :: [ String ]; to :: [ String ]; } -> { keys :: [ String ]; module :: Function; }
    ```

    # Examples
    :::{.example}
    ## `lib.hm.deprecations.mkSettingsOverlay` usage example

    ```nix
    let
      overlay = lib.hm.deprecations.mkSettingsOverlay {
        inherit options;
        from = [ "programs" "example" "extraConfig" ];
        to = [ "programs" "example" "settings" ];
      };
    in {
      imports = [ overlay.module ];
    }
    ```

    :::
  */
  mkSettingsOverlay =
    {
      options,
      from,
      to,
    }:
    let
      old = lib.getAttrFromPath from options;
      active = old.isDefined && old.highestPrio <= (lib.mkOptionDefault { }).priority;
      definitions = lib.optionals active old.definitionsWithLocations;
    in
    {
      keys = builtins.attrNames ((lib.types.attrsOf lib.types.raw).merge from definitions);

      module = mkRenamedOptionModuleWith {
        inherit from to;
        condition = active;
        value =
          let
            withRootPriority =
              value:
              if (value._type or null) == "override" then
                value
              else if (value._type or null) == "if" then
                lib.mkIf value.condition (withRootPriority value.content)
              else if (value._type or null) == "merge" then
                lib.mkMerge (map withRootPriority value.contents)
              else if (value._type or null) == "definition" then
                value // { value = withRootPriority value.value; }
              else
                lib.mkOverride old.highestPrio value;
          in
          lib.mkMerge (map (definition: lib.mapAttrs (_: withRootPriority) definition.value) definitions);
      };
    };

  /**
    Recursively transform attribute set keys and warn for each transformation.

    Lists are traversed by index. Other values are returned unchanged.

    # Inputs

    `pred`

    : Predicate that returns whether a key should be transformed.

    `transform`

    : Function that transforms a key.

    `ignore` (list of strings; optional)

    : Keys to never transform, even when `pred` matches. Defaults to `[ ]`.

    `pathStr`

    : Initial option path used in warning messages.

    `attrs`

    : Value to traverse, including nested attribute sets and lists.

    # Type

    ```
    remapAttrsRecursive :: AttrSet -> String -> Any -> Any
    ```

    # Examples
    :::{.example}
    ## `lib.hm.deprecations.remapAttrsRecursive` usage example

    ```nix
    let
      migrateCamelCase = lib.hm.deprecations.remapAttrsRecursive {
        pred = key: builtins.match ".*[a-z][A-Z].*" key != null;
        transform = lib.hm.strings.toSnakeCase;
        ignore = [ "allowThisOne" ];
      };
    in
      migrateCamelCase "programs.mymodule.settings" {
        someSetting = 1;
        allowThisOne = 2;
      }
      # => { some_setting = 1; allowThisOne = 2; }
    ```

    :::
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

  /**
    Build state-version migration values for options whose defaults change.

    In either mode, the result contains `default`, `defaultText`, `effectiveDefault`,
    `warning`, `shouldWarn`, and `optionUsesDefaultPriority`. In direct mode,
    `default` uses `legacy.value` only when the state version is older than
    `since` and the values differ. This emits the warning with `lib.warn`.
    In deferred mode, `default` remains `current.value`, and the caller can add
    `warning` to `config.warnings`. Deferred mode requires both `config` and
    `options`. This lets explicit assignments suppress warnings for merged
    attribute-set options, where warning from the default itself is too early.

    `defaultText` describes the state-version choice for `mkOption` documentation.
    `effectiveDefault` is the state-version-selected value.
    `optionUsesDefaultPriority` reports whether the option's priority is at least
    `warningPriority`. `shouldWarn` reports whether to add `warning` to the configuration.

    `legacy` and `current` each require `value` and may provide optional `text`.
    `shouldWarn` is ignored when it is `null` or a boolean. When it is a
    function, the function receives `{ optionInfo, optionUsesDefaultPriority }`
    and returns whether to warn. Deferred warnings are emitted only for the
    legacy branch when the values differ.

    # Inputs

    `stateVersion`

    : Current `home.stateVersion`.

    `since`

    : State version at which the current default applies.

    `optionPath`

    : Option path whose default is migrating.

    `legacy`

    : Default `value` and optional display `text`; text defaults to pretty-printed `value`.

    `current`

    : Default `value` and optional display `text`; text defaults to pretty-printed `value`.

    `extraWarning` (string; optional)

    : Additional warning text. Defaults to `""`.

    `config` (attribute set or null; optional)

    : Module configuration, required for deferred mode. Defaults to `null`.

    `options` (attribute set or null; optional)

    : Module option definitions, required for deferred mode. Defaults to `null`.

    `warningPriority` (integer; optional)

    : Priority threshold for the default-priority check. Defaults to the option default priority.

    `shouldWarn` (boolean, function, or null; optional)

    : Optional callback; other values use `optionUsesDefaultPriority`. Defaults to `null`.

    `deferWarningToConfig` (boolean; optional)

    : Defer warnings to `config.warnings`. Defaults to `false`.

    # Type

    ```
    mkStateVersionOptionDefault :: AttrSet -> AttrSet
    ```

    # Examples
    :::{.example}
    ## `lib.hm.deprecations.mkStateVersionOptionDefault` usage example

    ```nix
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
      }
    ```

    Deferred warnings require `config` and `options`:

    ```nix
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
    }
    ```

    :::
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
      valuesEqual = legacy.value == current.value;
    in
    assert lib.assertMsg (!deferWarningToConfig || canDeferWarning) ''
      `lib.hm.deprecations.mkStateVersionOptionDefault` requires both `config` and `options`
      when `deferWarningToConfig = true`.
    '';
    {
      default =
        if usingLegacyBranch && !deferWarningToConfig && !valuesEqual then
          lib.warn warning legacy.value
        else
          current.value;
      defaultText = lib.literalExpression ''
        if lib.versionAtLeast config.home.stateVersion "${since}" then ${currentText} else ${legacyText}
      '';
      effectiveDefault = if usingLegacyBranch then legacy.value else current.value;
      inherit warning optionUsesDefaultPriority;
      shouldWarn =
        deferWarningToConfig
        && usingLegacyBranch
        && !valuesEqual
        && (
          if lib.isFunction shouldWarn then
            shouldWarn { inherit optionInfo optionUsesDefaultPriority; }
          else
            optionUsesDefaultPriority
        );
    };

  /**
    Build a predicate that detects an omitted field when another field has a meaningful value.

    # Inputs

    `omittedField`

    : Field whose absence triggers the warning.

    `triggerField`

    : Field whose meaningful value enables the warning.

    `triggerPredicate` (function; optional)

    : Predicate for the trigger field value. Defaults to rejecting `null` and `""`.

    `entry`

    : Record containing `value`. Returns false when `value` is not an attribute set.

    # Type

    ```
    mkListEntryOmittedFieldPredicate :: { omittedField :: String; triggerField :: String; triggerPredicate ? Function; } -> { value :: Any; ... } -> Bool
    ```

    # Examples
    :::{.example}
    ## `lib.hm.deprecations.mkListEntryOmittedFieldPredicate` usage example

    ```nix
    lib.hm.deprecations.mkListEntryOmittedFieldPredicate {
      omittedField = "type";
      triggerField = "config";
    } { value.config = "configured"; }
    => true
    ```

    :::
  */
  mkListEntryOmittedFieldPredicate =
    {
      omittedField,
      triggerField,
      triggerPredicate ? (value: value != null && value != ""),
    }:
    entry:
    builtins.isAttrs entry.value
    && builtins.hasAttr triggerField entry.value
    && triggerPredicate (builtins.getAttr triggerField entry.value)
    && !(builtins.hasAttr omittedField entry.value);

  /**
    Build state-version migration warnings for entries in a list option.

    The caller supplies a predicate that identifies raw entries relying on the
    legacy implicit behavior. Use this for list submodules or attribute sets
    whose field defaults would otherwise produce noisy warnings.
    Callbacks receive `{ index, file, value }`, with a one-based index and the
    source file's base name. The result is empty when `stateVersion` is at
    least `since`, or when no entry matches the predicate.

    # Inputs

    `stateVersion`

    : Current `home.stateVersion`.

    `since`

    : State version at which the current behavior applies.

    `baseWarning`

    : State-version migration warning text.

    `definitions`

    : Definition records from `definitionsWithLocations`; each `value` is a list.

    `shouldWarnEntry`

    : Predicate that returns whether an entry relies on legacy behavior.

    `describeEntry` (function; optional)

    : Describes an entry in the warning. Defaults to `"an entry"`.

    `extraEntryWarning` (function; optional)

    : Returns additional warning text for an entry. Defaults to `""`.

    # Type

    ```
    mkStateVersionListSubmoduleWarnings :: AttrSet -> [ String ]
    ```

    # Examples
    :::{.example}
    ## `lib.hm.deprecations.mkStateVersionListSubmoduleWarnings` usage example

    ```nix
    let
      stateVersionDefault = lib.hm.deprecations.mkStateVersionOptionDefault {
        inherit (config.home) stateVersion;
        since = "26.05";
        optionPath = [ "programs" "example" "entries" "ENTRY" "mode" ];
        legacy.value = "old";
        current.value = "new";
      };
    in
    lib.hm.deprecations.mkStateVersionListSubmoduleWarnings {
      inherit (config.home) stateVersion;
      since = "26.05";
      baseWarning = stateVersionDefault.warning;
      definitions = options.programs.example.entries.definitionsWithLocations;
      shouldWarnEntry = entry:
        builtins.isAttrs entry.value
        && entry.value ? config
        && entry.value.config != null
        && !(entry.value ? mode);
      describeEntry = entry: "entry `${entry.value.name}`";
    }
    ```

    :::
  */
  mkStateVersionListSubmoduleWarnings =
    {
      stateVersion,
      since,
      baseWarning,
      definitions,
      shouldWarnEntry,
      describeEntry ? (_entry: "an entry"),
      extraEntryWarning ? (_entry: ""),
    }:
    let
      flattenedDefinitions = lib.concatMap (
        definition:
        lib.imap1 (index: value: {
          inherit index value;
          file = baseNameOf (toString definition.file);
        }) definition.value
      ) definitions;

      formatEntryWarning =
        entry:
        let
          entryWarning = extraEntryWarning entry;
        in
        lib.concatStringsSep "\n" (
          [
            (lib.removeSuffix "\n" baseWarning)
            "Triggered by ${describeEntry entry} defined in `${entry.file}` at list index ${toString entry.index}."
          ]
          ++ lib.optional (entryWarning != "") entryWarning
        );
    in
    lib.optionals (lib.versionOlder stateVersion since) (
      map formatEntryWarning (builtins.filter shouldWarnEntry flattenedDefinitions)
    );
}
