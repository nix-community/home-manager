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
  /*
    Builds a standard warning for an option value shape that is deprecated.

    Example:
      mkDeprecatedOptionValueWarning {
        option = [ "programs" "example" "settings" ];
        old = "a list";
        replacement = "`programs.example.settings.items`";
      }

    => Using `programs.example.settings` as a list is deprecated and will be
       removed in a future release. Please use `programs.example.settings.items`
       instead.
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

  # Builds a standard warning for an option value that has been renamed.
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

    Set preserveOrder when list definitions from the old and new paths must
    retain their relative mkBefore and mkAfter ordering.
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

  /*
    Migrates a default-empty attribute-set overlay to freeform settings.
    Returns a module to import and the effective immediate keys, which callers
    can use to suppress modeled values formerly overwritten by the overlay.

    Root priorities apply only to supplied keys. Explicit key priorities and
    nested definitions remain intact. Keys with only disabled conditions are
    absent; null and empty values still count as supplied.

    Example:
      overlay = lib.hm.deprecations.mkSettingsOverlay {
        inherit options;
        from = [ "programs" "example" "extraConfig" ];
        to = [ "programs" "example" "settings" ];
      };

      imports = [ overlay.module ];
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

  /*
    Builds a predicate for list-entry warnings where an omitted field should
    trigger only when another field is present with a meaningful value.

    Example:
      shouldWarnEntry = lib.hm.deprecations.mkListEntryOmittedFieldPredicate {
        omittedField = "type";
        triggerField = "config";
      };
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

  /*
    Builds state-version migration warnings for entries in a list option whose
    items are typically submodules or attrsets.

    This is intended for cases where a field inside each entry has a
    state-version-dependent default, but warning from that field's option
    default is too noisy. The caller supplies a predicate that determines
    whether a raw entry relies on the legacy implicit behavior.

    Example:
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
      };
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
