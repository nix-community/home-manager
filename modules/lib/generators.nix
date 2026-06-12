{ lib }:

let
  isDAGEntryWithOrdering' =
    entry: lib.hm.dag.isEntry entry && (entry.after != [ ] || entry.before != [ ]);
  hasDAGEntryWithOrdering' = attrs: lib.any isDAGEntryWithOrdering' (lib.attrValues attrs);
  sortDAGEntries' =
    {
      cycleErrorMessage ? "Dependency cycle in DAG entries",
    }:
    attrs:
    let
      dag = lib.mapAttrs (
        _: entry: if lib.hm.dag.isEntry entry then entry else lib.hm.dag.entryAnywhere entry
      ) attrs;
      sortedDag = lib.hm.dag.topoSort dag;
      entries = sortedDag.result or (abort "${cycleErrorMessage}: ${builtins.toJSON sortedDag}");
    in
    map (entry: {
      inherit (entry) name;
      value = entry.data;
    }) entries;

  # Freeform generators can use this to support DAG ordering while preserving
  # entryAnywhere-shaped plain values beside ordered DAG entries.
  toDAGOrderedAttrs' =
    {
      cycleErrorMessage ? "Dependency cycle in DAG entries",
    }:
    attrs:
    if hasDAGEntryWithOrdering' attrs then
      sortDAGEntries' { inherit cycleErrorMessage; } (
        lib.mapAttrs (
          _: entry: if isDAGEntryWithOrdering' entry then entry else lib.hm.dag.entryAnywhere entry
        ) attrs
      )
    else
      lib.mapAttrsToList (name: value: { inherit name value; }) attrs;

  toDAGOrderedText' =
    {
      renderAttrs,
      renderList,
      renderValue,
      cycleErrorMessage ? "Dependency cycle in DAG entries",
    }:
    let
      render =
        value:
        if lib.isDerivation value || builtins.isPath value then
          renderValue value
        else if builtins.isAttrs value then
          renderAttrs (
            map (entry: entry // { value = render entry.value; }) (
              toDAGOrderedAttrs' { inherit cycleErrorMessage; } value
            )
          )
        else if builtins.isList value then
          renderList (map render value)
        else
          renderValue value;
    in
    render;

  toDAGOrderedJsonText' =
    {
      cycleErrorMessage ? "Dependency cycle in DAG entries",
    }:
    toDAGOrderedText' {
      inherit cycleErrorMessage;
      renderValue = builtins.toJSON;
      renderList = values: "[${lib.concatStringsSep "," values}]";
      renderAttrs =
        attrs:
        let
          renderAttr = entry: "${builtins.toJSON entry.name}:${entry.value}";
        in
        "{${lib.concatMapStringsSep "," renderAttr attrs}}";
    };

  toDAGOrderedKeyValue' =
    {
      mkKeyValue ? lib.generators.mkKeyValueDefault { } "=",
      listsAsDuplicateKeys ? false,
      listToValue ? null,
      indent ? "",
      cycleErrorMessage ? "Dependency cycle in DAG entries",
    }:
    assert listsAsDuplicateKeys -> listToValue == null;
    attrs:
    let
      normalizeValue =
        value: if listToValue != null && builtins.isList value then listToValue value else value;
      mkLine = name: value: indent + mkKeyValue name value + "\n";
      mkLines =
        if listsAsDuplicateKeys then
          name: value: map (mkLine name) (if builtins.isList value then value else [ value ])
        else
          name: value: [ (mkLine name (normalizeValue value)) ];
    in
    lib.concatStrings (
      lib.concatMap (entry: mkLines entry.name entry.value) (
        toDAGOrderedAttrs' { inherit cycleErrorMessage; } attrs
      )
    );

  toDAGOrderedINI' =
    {
      mkSectionName ? (name: lib.escape [ "[" "]" ] name),
      mkKeyValue ? lib.generators.mkKeyValueDefault { } "=",
      listsAsDuplicateKeys ? false,
      listToValue ? null,
      cycleErrorMessage ? "Dependency cycle in INI sections",
    }:
    assert listsAsDuplicateKeys -> listToValue == null;
    attrsOfAttrs:
    let
      mkSection =
        section:
        ''
          [${mkSectionName section.name}]
        ''
        + toDAGOrderedKeyValue' {
          inherit
            cycleErrorMessage
            listToValue
            listsAsDuplicateKeys
            mkKeyValue
            ;
        } section.value;
    in
    lib.concatStringsSep "\n" (
      map mkSection (toDAGOrderedAttrs' { inherit cycleErrorMessage; } attrsOfAttrs)
    );

  mkDAGOrderedFormat' =
    {
      pkgs,
      format,
      generator,
      nativeBuildInputs ? [ ],
      buildCommand ? ''
        cp "$valuePath" "$out"
      '',
      cycleErrorMessage ? null,
    }:
    format
    // {
      generate =
        name: value:
        pkgs.runCommandLocal name {
          inherit nativeBuildInputs;
          value = generator {
            cycleErrorMessage =
              if cycleErrorMessage == null then "Dependency cycle in ${name}" else cycleErrorMessage;
          } value;
          # Nix does not populate $valuePath when __structuredAttrs is true.
          passAsFile = [ "value" ];
        } buildCommand;
    };
in
{
  /**
    Returns whether a value is a Home Manager DAG entry with ordering metadata.

    # Inputs

    `entry`

    : 1\. Function argument

    # Type

    ```
    isDAGEntryWithOrdering :: Any -> Bool
    ```
  */
  isDAGEntryWithOrdering = isDAGEntryWithOrdering';

  /**
    Returns whether an attribute set contains any Home Manager DAG entry with
    ordering metadata.

    # Inputs

    `attrs`

    : 1\. Function argument

    # Type

    ```
    hasDAGEntryWithOrdering :: AttrSet -> Bool
    ```
  */
  hasDAGEntryWithOrdering = hasDAGEntryWithOrdering';

  /**
    Topologically sort an attribute set that contains Home Manager DAG entries.
    Plain sibling values are treated as unordered DAG entries.

    # Inputs

    `options`

    : Function options

      `cycleErrorMessage` (string; optional)
      : Message prefix to use when a dependency cycle is detected.

    `attrs`

    : Attribute set to sort

    # Type

    ```
    sortDAGEntries :: { cycleErrorMessage ? String } -> AttrSet -> [ { name :: String; value :: Any; } ]
    ```

    # Examples
    :::{.example}
    ## `lib.hm.generators.sortDAGEntries` usage example

    ```nix
    lib.hm.generators.sortDAGEntries { } {
      after = lib.hm.dag.entryAfter [ "before" ] "2";
      before = "1";
    }
    => [
      { name = "before"; value = "1"; }
      { name = "after"; value = "2"; }
    ]
    ```

    :::
  */
  sortDAGEntries = sortDAGEntries';

  /**
    Convert an attribute set to a list of name/value pairs, using topological
    ordering when any value is a Home Manager DAG entry with non-empty ordering
    metadata.

    This is intended for freeform generators that should support optional DAG
    ordering while preserving entryAnywhere-shaped plain values.

    # Inputs

    `options`

    : Function options

      `cycleErrorMessage` (string; optional)
      : Message prefix to use when a dependency cycle is detected.

    `attrs`

    : Attribute set to convert

    # Type

    ```
    toDAGOrderedAttrs :: { cycleErrorMessage ? String } -> AttrSet -> [ { name :: String; value :: Any; } ]
    ```
  */
  toDAGOrderedAttrs = toDAGOrderedAttrs';

  /**
    Render Nix values to text using caller-provided render functions while
    preserving ordering from nested Home Manager DAG entries.

    # Inputs

    `options`

    : Function options

      `renderAttrs` (function)
      : Render ordered attribute entries. Receives a list of
        `{ name, value }` entries where `value` is already rendered text.

      `renderList` (function)
      : Render list values. Receives rendered element strings.

      `renderValue` (function)
      : Render scalar values, paths, and derivations.

      `cycleErrorMessage` (string; optional)
      : Message prefix to use when a dependency cycle is detected.

    `value`

    : Value to render

    # Type

    ```
    toDAGOrderedText :: { renderAttrs :: Function; renderList :: Function; renderValue :: Function; cycleErrorMessage ? String; } -> Any -> String
    ```
  */
  toDAGOrderedText = toDAGOrderedText';

  /**
    Generate a key-value-style config file from an attribute set, preserving
    ordering from Home Manager DAG entries.

    # Inputs

    `options`

    : Function options

      `mkKeyValue` (function; optional)
      : Format a setting line from name and value.

      `listsAsDuplicateKeys` (boolean; optional)
      : Render list values as duplicate keys.

      `listToValue` (function or null; optional)
      : Convert list values to scalar values before rendering.

      `indent` (string; optional)
      : Initial indentation level.

      `cycleErrorMessage` (string; optional)
      : Message prefix to use when a dependency cycle is detected.

    `attrs`

    : Attribute set to render

    # Type

    ```
    toDAGOrderedKeyValue :: { mkKeyValue ? Function; listsAsDuplicateKeys ? Bool; listToValue ? NullOr Function; indent ? String; cycleErrorMessage ? String; } -> AttrSet -> String
    ```
  */
  toDAGOrderedKeyValue = toDAGOrderedKeyValue';

  /**
    Generate an INI-style config file from an attribute set of sections while
    preserving ordering from Home Manager DAG entries.

    # Inputs

    `options`

    : Function options

      `mkSectionName` (function; optional)
      : Format a section name.

      `mkKeyValue` (function; optional)
      : Format a setting line from name and value.

      `listsAsDuplicateKeys` (boolean; optional)
      : Render list values as duplicate keys.

      `listToValue` (function or null; optional)
      : Convert list values to scalar values before rendering.

      `cycleErrorMessage` (string; optional)
      : Message prefix to use when a dependency cycle is detected.

    `attrsOfAttrs`

    : Attribute set of sections to render

    # Type

    ```
    toDAGOrderedINI :: { mkSectionName ? Function; mkKeyValue ? Function; listsAsDuplicateKeys ? Bool; listToValue ? NullOr Function; cycleErrorMessage ? String; } -> AttrSet -> String
    ```
  */
  toDAGOrderedINI = toDAGOrderedINI';

  /**
    Wrap a `pkgs.formats` format so its `generate` function can render
    Home Manager DAG entries in order.

    # Inputs

    `options`

    : Function options

      `pkgs` (attribute set)
      : Package set used to create the generated derivation.

      `format` (attribute set)
      : Existing format value, for example `pkgs.formats.json { }`.

      `generator` (function)
      : Text renderer. Receives `{ cycleErrorMessage }` and returns a function
        from value to rendered text.

      `nativeBuildInputs` (list; optional)
      : Build inputs needed by `buildCommand`.

      `buildCommand` (string; optional)
      : Builder script. Defaults to copying rendered text to `$out`.

      `cycleErrorMessage` (string or null; optional)
      : Message prefix to use when a dependency cycle is detected. When `null`,
        the generated file name is used.

    # Type

    ```
    mkDAGOrderedFormat :: { pkgs :: AttrSet; format :: AttrSet; generator :: Function; nativeBuildInputs ? [Derivation]; buildCommand ? String; cycleErrorMessage ? NullOr String; } -> AttrSet
    ```
  */
  mkDAGOrderedFormat = mkDAGOrderedFormat';

  /**
    Create a JSON format whose `generate` function renders nested ordered Home
    Manager DAG entries in order.

    # Inputs

    `options`

    : Function options

      `pkgs` (attribute set)
      : Package set used to create the generated derivation.

      `jsonFormat` (attribute set; optional)
      : Existing JSON format value. Defaults to `pkgs.formats.json { }`.

      `cycleErrorMessage` (string or null; optional)
      : Message prefix to use when a dependency cycle is detected. When `null`,
        the generated file name is used.

    # Type

    ```
    mkDAGOrderedJsonFormat :: { pkgs :: AttrSet; jsonFormat ? AttrSet; cycleErrorMessage ? NullOr String; } -> AttrSet
    ```
  */
  mkDAGOrderedJsonFormat =
    {
      pkgs,
      jsonFormat ? pkgs.formats.json { },
      cycleErrorMessage ? null,
    }:
    mkDAGOrderedFormat' {
      inherit
        pkgs
        cycleErrorMessage
        ;
      format = jsonFormat;
      generator = { cycleErrorMessage }: toDAGOrderedJsonText' { inherit cycleErrorMessage; };
      nativeBuildInputs = [ pkgs.buildPackages.jq ];
      buildCommand = ''
        jq . "$valuePath" > "$out"
      '';
    };

  /**
    Create a YAML format whose `generate` function renders nested ordered Home
    Manager DAG entries in order.

    # Inputs

    `options`

    : Function options

      `pkgs` (attribute set)
      : Package set used to create the generated derivation.

      `yamlFormat` (attribute set; optional)
      : Existing YAML format value. Defaults to `pkgs.formats.yaml { }`.

      `cycleErrorMessage` (string or null; optional)
      : Message prefix to use when a dependency cycle is detected. When `null`,
        the generated file name is used.

    # Type

    ```
    mkDAGOrderedYamlFormat :: { pkgs :: AttrSet; yamlFormat ? AttrSet; cycleErrorMessage ? NullOr String; } -> AttrSet
    ```
  */
  mkDAGOrderedYamlFormat =
    {
      pkgs,
      yamlFormat ? pkgs.formats.yaml { },
      cycleErrorMessage ? null,
    }:
    mkDAGOrderedFormat' {
      inherit
        pkgs
        cycleErrorMessage
        ;
      format = yamlFormat;
      generator = { cycleErrorMessage }: toDAGOrderedJsonText' { inherit cycleErrorMessage; };
      nativeBuildInputs = [ pkgs.buildPackages.remarshal ];
      buildCommand = ''
        json2yaml "$valuePath" "$out"
      '';
    };

  /**
    Create a TOML format whose `generate` function renders nested ordered Home
    Manager DAG entries in order.

    # Inputs

    `options`

    : Function options

      `pkgs` (attribute set)
      : Package set used to create the generated derivation.

      `tomlFormat` (attribute set; optional)
      : Existing TOML format value. Defaults to `pkgs.formats.toml { }`.

      `cycleErrorMessage` (string or null; optional)
      : Message prefix to use when a dependency cycle is detected. When `null`,
        the generated file name is used.

    # Type

    ```
    mkDAGOrderedTomlFormat :: { pkgs :: AttrSet; tomlFormat ? AttrSet; cycleErrorMessage ? NullOr String; } -> AttrSet
    ```
  */
  mkDAGOrderedTomlFormat =
    {
      pkgs,
      tomlFormat ? pkgs.formats.toml { },
      cycleErrorMessage ? null,
    }:
    mkDAGOrderedFormat' {
      inherit
        pkgs
        cycleErrorMessage
        ;
      format = tomlFormat;
      generator = { cycleErrorMessage }: toDAGOrderedJsonText' { inherit cycleErrorMessage; };
      nativeBuildInputs = [ pkgs.buildPackages.remarshal ];
      buildCommand = ''
        json2toml "$valuePath" "$out"
      '';
    };

  /**
    Create an INI format whose `generate` function renders ordered Home Manager
    DAG entries in order.

    # Inputs

    `options`

    : Function options

      `pkgs` (attribute set)
      : Package set used to create the generated derivation.

      `iniFormat` (attribute set; optional)
      : Existing INI format value. Defaults to `pkgs.formats.ini { ... }`.

      `listsAsDuplicateKeys`, `listToValue`, `atomsCoercedToLists`
      : Format options matching `pkgs.formats.ini`.

      `mkSectionName`, `mkKeyValue`
      : Format options for rendering section and setting lines.

      `cycleErrorMessage` (string or null; optional)
      : Message prefix to use when a dependency cycle is detected. When `null`,
        the generated file name is used.

    # Type

    ```
    mkDAGOrderedIniFormat :: { pkgs :: AttrSet; iniFormat ? AttrSet; mkSectionName ? Function; mkKeyValue ? Function; listsAsDuplicateKeys ? Bool; listToValue ? NullOr Function; atomsCoercedToLists ? NullOr Bool; cycleErrorMessage ? NullOr String; } -> AttrSet
    ```
  */
  mkDAGOrderedIniFormat =
    {
      pkgs,
      mkSectionName ? (name: lib.escape [ "[" "]" ] name),
      mkKeyValue ? lib.generators.mkKeyValueDefault { } "=",
      listsAsDuplicateKeys ? false,
      listToValue ? null,
      atomsCoercedToLists ? null,
      iniFormat ? pkgs.formats.ini {
        inherit
          atomsCoercedToLists
          listsAsDuplicateKeys
          listToValue
          ;
      },
      cycleErrorMessage ? null,
    }:
    assert listsAsDuplicateKeys -> listToValue == null;
    mkDAGOrderedFormat' {
      inherit
        pkgs
        cycleErrorMessage
        ;
      format = iniFormat;
      generator =
        { cycleErrorMessage }:
        toDAGOrderedINI' {
          inherit
            cycleErrorMessage
            listToValue
            listsAsDuplicateKeys
            mkKeyValue
            mkSectionName
            ;
        };
    };

  /**
    Create a key-value format whose `generate` function renders ordered Home
    Manager DAG entries in order.

    # Inputs

    `options`

    : Function options

      `pkgs` (attribute set)
      : Package set used to create the generated derivation.

      `keyValueFormat` (attribute set; optional)
      : Existing key-value format value. Defaults to `pkgs.formats.keyValue`.

      `listsAsDuplicateKeys`, `listToValue`
      : Format options matching `pkgs.formats.keyValue`.

      `mkKeyValue`
      : Format option for rendering setting lines.

      `cycleErrorMessage` (string or null; optional)
      : Message prefix to use when a dependency cycle is detected. When `null`,
        the generated file name is used.

    # Type

    ```
    mkDAGOrderedKeyValueFormat :: { pkgs :: AttrSet; keyValueFormat ? AttrSet; mkKeyValue ? Function; listsAsDuplicateKeys ? Bool; listToValue ? NullOr Function; cycleErrorMessage ? NullOr String; } -> AttrSet
    ```
  */
  mkDAGOrderedKeyValueFormat =
    {
      pkgs,
      mkKeyValue ? lib.generators.mkKeyValueDefault { } "=",
      listsAsDuplicateKeys ? false,
      listToValue ? null,
      keyValueFormat ? pkgs.formats.keyValue {
        inherit listsAsDuplicateKeys listToValue;
      },
      cycleErrorMessage ? null,
    }:
    assert listsAsDuplicateKeys -> listToValue == null;
    mkDAGOrderedFormat' {
      inherit
        pkgs
        cycleErrorMessage
        ;
      format = keyValueFormat;
      generator =
        { cycleErrorMessage }:
        toDAGOrderedKeyValue' {
          inherit
            cycleErrorMessage
            listToValue
            listsAsDuplicateKeys
            mkKeyValue
            ;
        };
    };

  toHyprconf =
    {
      attrs,
      indentLevel ? 0,
      importantPrefixes ? [ "$" ],
    }:
    let
      inherit (lib)
        all
        any
        concatMapStringsSep
        concatStrings
        concatStringsSep
        filterAttrs
        generators
        hasPrefix
        isAttrs
        isList
        mapAttrsToList
        replicate
        attrNames
        ;

      initialIndent = concatStrings (replicate indentLevel "  ");

      toHyprconf' =
        indent: attrs:
        let
          isImportantField = n: _: any (prev: hasPrefix prev n) importantPrefixes;
          importantFields = filterAttrs isImportantField attrs;
          withoutImportantFields = fields: removeAttrs fields (attrNames importantFields);

          allSections = filterAttrs (_n: v: isAttrs v || isList v) attrs;
          sections = withoutImportantFields allSections;

          mkSection =
            n: attrs:
            if isList attrs then
              let
                separator = if all isAttrs attrs then "\n" else "";
              in
              (concatMapStringsSep separator (a: mkSection n a) attrs)
            else if isAttrs attrs then
              ''
                ${indent}${n} {
                ${toHyprconf' "  ${indent}" attrs}${indent}}
              ''
            else
              toHyprconf' indent { ${n} = attrs; };

          mkFields = generators.toKeyValue {
            listsAsDuplicateKeys = true;
            inherit indent;
          };

          allFields = filterAttrs (_n: v: !(isAttrs v || isList v)) attrs;
          fields = withoutImportantFields allFields;
        in
        mkFields importantFields
        + concatStringsSep "\n" (mapAttrsToList mkSection sections)
        + mkFields fields;
    in
    toHyprconf' initialIndent attrs;

  toKDL =
    _:
    let
      inherit (lib)
        concatStringsSep
        mapAttrsToList
        any
        ;
      inherit (builtins) typeOf replaceStrings elem;

      # ListOf String -> String
      indentStrings =
        let
          # Although the input of this function is a list of strings,
          # the strings themselves *will* contain newlines, so you need
          # to normalize the list by joining and resplitting them.
          unlines = lib.splitString "\n";
          lines = lib.concatStringsSep "\n";
          indentAll = lines: concatStringsSep "\n" (map (x: "	" + x) lines);
        in
        stringsWithNewlines: indentAll (unlines (lines stringsWithNewlines));

      # String -> String
      sanitizeString = replaceStrings [ "\n" ''"'' ] [ "\\n" ''\"'' ];

      # OneOf [Int Float String Bool Null] -> String
      literalValueToString =
        element:
        lib.throwIfNot
          (elem (typeOf element) [
            "int"
            "float"
            "string"
            "bool"
            "null"
          ])
          "Cannot convert value of type ${typeOf element} to KDL literal."
          (
            if typeOf element == "null" then
              "null"
            else if element == false then
              "false"
            else if element == true then
              "true"
            else if typeOf element == "string" then
              ''"${sanitizeString element}"''
            else
              toString element
          );

      # Attrset Conversion
      # String -> AttrsOf Anything -> String
      convertAttrsToKDL =
        name: attrs:
        let
          optArgs = map literalValueToString (attrs._args or [ ]);
          optProps = lib.mapAttrsToList (name: value: "${name}=${literalValueToString value}") (
            attrs._props or { }
          );

          orderedChildren = lib.pipe (attrs._children or [ ]) [
            (map (child: mapAttrsToList convertAttributeToKDL child))
            lib.flatten
          ];
          unorderedChildren = lib.pipe attrs [
            (lib.filterAttrs (
              name: _:
              !(elem name [
                "_args"
                "_props"
                "_children"
              ])
            ))
            (mapAttrsToList convertAttributeToKDL)
          ];
          children = orderedChildren ++ unorderedChildren;
          optChildren = lib.optional (children != [ ]) ''
            {
            ${indentStrings children}
            }'';

        in
        lib.concatStringsSep " " ([ name ] ++ optArgs ++ optProps ++ optChildren);

      # List Conversion
      # String -> ListOf (OneOf [Int Float String Bool Null])  -> String
      convertListOfFlatAttrsToKDL =
        name: list:
        let
          flatElements = map literalValueToString list;
        in
        "${name} ${concatStringsSep " " flatElements}";

      # String -> ListOf Anything -> String
      convertListOfNonFlatAttrsToKDL = name: list: ''
        ${name} {
        ${indentStrings (map (x: convertAttributeToKDL "-" x) list)}
        }'';

      # String -> ListOf Anything  -> String
      convertListToKDL =
        name: list:
        let
          elementsAreFlat =
            !any (
              el:
              elem (typeOf el) [
                "list"
                "set"
              ]
            ) list;
        in
        if elementsAreFlat then
          convertListOfFlatAttrsToKDL name list
        else
          convertListOfNonFlatAttrsToKDL name list;

      # Combined Conversion
      # String -> Anything  -> String
      convertAttributeToKDL =
        name: value:
        let
          vType = typeOf value;
        in
        if
          elem vType [
            "int"
            "float"
            "bool"
            "null"
            "string"
          ]
        then
          "${name} ${literalValueToString value}"
        else if vType == "set" then
          convertAttrsToKDL name value
        else if vType == "list" then
          if name == "_children" then
            concatStringsSep "\n" (
              map (lib.flip lib.pipe [
                (mapAttrsToList convertAttributeToKDL)
                (concatStringsSep "\n")
              ]) value
            )
          else
            convertListToKDL name value
        else
          throw ''
            Cannot convert type `(${typeOf value})` to KDL:
              ${name} = ${toString value}
          '';
    in
    attrs: ''
      ${concatStringsSep "\n" (mapAttrsToList convertAttributeToKDL attrs)}
    '';

  toSCFG =
    _:
    let
      inherit (lib) concatStringsSep any;
      inherit (builtins) typeOf replaceStrings elem;

      filterNullDirectives = lib.filter (
        directive:
        !(directive ? "params" || directive ? "children")
        || !(directive.params or [ null ] == [ null ] && directive.children or [ ] == [ ])
      );

      # ListOf String -> String
      indentStrings =
        let
          # Although the input of this function is a list of strings,
          # the strings themselves *will* contain newlines, so you need
          # to normalize the list by joining and resplitting them.
          unlines = lib.splitString "\n";
          lines = concatStringsSep "\n";
          indentAll = lines: concatStringsSep "\n" (map (x: "\t" + x) lines);
        in
        stringsWithNewlines: indentAll (unlines (lines stringsWithNewlines));

      # String -> Bool
      specialChars =
        s:
        any (
          char:
          elem char (
            reserved
            ++ [
              " "
              "'"
              "{"
              "}"
            ]
          )
        ) (lib.stringToCharacters s);

      # String -> String
      sanitizeString = replaceStrings reserved [
        ''\"''
        "\\\\"
        "\\r"
        "\\n"
        "\\t"
      ];

      reserved = [
        ''"''
        "\\"
        "\r"
        "\n"
        "\t"
      ];

      # OneOf [Int Float String Bool] -> String
      literalValueToString =
        element:
        lib.throwIfNot
          (elem (typeOf element) [
            "int"
            "float"
            "string"
            "bool"
          ])
          "Cannot convert value of type ${typeOf element} to SCFG literal."
          (
            if element == false then
              "false"
            else if element == true then
              "true"
            else if typeOf element == "string" then
              if element == "" || specialChars element then ''"${sanitizeString element}"'' else element
            else
              toString element
          );

      # Bool -> ListOf (OneOf [Int Float String Bool]) -> String
      toOptParamsString =
        cond: list:
        lib.optionalString cond (
          lib.pipe list [
            (map literalValueToString)
            (concatStringsSep " ")
            (s: " " + s)
          ]
        );

      # Directive Conversion
      # ListOf NameParamChildrenTriplet -> ListOf String
      convertDirectivesToSCFG =
        directives:
        map (
          directive:
          (literalValueToString directive.name)
          + toOptParamsString (directive ? "params" && directive.params != null) directive.params
          + lib.optionalString (directive ? "children" && directive.children != null) (
            " "
            + ''
              {
              ${indentStrings (convertDirectivesToSCFG directive.children)}
              }''
          )
        ) (filterNullDirectives directives);
    in
    directives:
    lib.optionalString (directives != [ ]) ''
      ${lib.concatStringsSep "\n" (convertDirectivesToSCFG directives)}
    '';
}
