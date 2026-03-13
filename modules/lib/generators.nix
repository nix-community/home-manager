{ lib }:

{
  toSwayConf =
    {
      outerBlock ? true,
      indent ? "",
      indentSpace ? "  ",
    }@args:
    v:
    let
      toSwayConf' =
        {
          outerBlock ? true,
          indent ? "",
          indentSpace ? "  ",
        }@args:
        v:
        let
          outroSpace = "\n" + lib.strings.removeSuffix indentSpace indent;
          outro = outroSpace + lib.optionalString (!outerBlock) "}";
          intro =
            lib.optionalString (!outerBlock) ''
              {
            ''
            + indent;

          innerArgs = args // {
            outerBlock = false;
            indent = indent + indentSpace;
          };
          genInner = key: value: builtins.toString key + indentSpace + toSwayConf' innerArgs value;
          concatItems = lib.concatStringsSep ''

            ${indent}'';
        in
        if lib.isInt v || lib.isFloat v || lib.isString v then
          (builtins.toString v)
        else if lib.isList v then
          intro + concatItems v + outro
        else if lib.isAttrs v then
          (
            if v == { } then
              abort "toSwayConfig: empty attribute set is unsupported"
            else
              intro + concatItems (lib.mapAttrsToList genInner v) + outro
          )
        else
          (abort "toSwayConfig: type ${builtins.typeOf v} is unsupported");

      # include and set should be at the top of the configuration
      setSettings = lib.filterAttrs (key: _: key == "set") v;
      includeSettings = lib.filterAttrs (key: _: key == "include") v;
      otherSettings = lib.filterAttrs (key: _: key != "set" && key != "include") v;
    in
    lib.optionalString (setSettings != { }) (toSwayConf' args setSettings)
    + lib.optionalString (includeSettings != { }) (toSwayConf' args includeSettings)
    + lib.optionalString (otherSettings != { }) (toSwayConf' args otherSettings);

  toHyprconf =
    {
      attrs,
      indentLevel ? 0,
      importantPrefixes ? [ "$" ],
    }:
    let
      inherit (lib)
        all
        concatMapStringsSep
        concatStrings
        concatStringsSep
        filterAttrs
        foldl
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
          isImportantField =
            n: _: foldl (acc: prev: if hasPrefix prev n then true else acc) false importantPrefixes;
          importantFields = filterAttrs isImportantField attrs;
          withoutImportantFields = fields: removeAttrs fields (attrNames importantFields);

          allSections = filterAttrs (n: v: isAttrs v || isList v) attrs;
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

          allFields = filterAttrs (n: v: !(isAttrs v || isList v)) attrs;
          fields = withoutImportantFields allFields;
        in
        mkFields importantFields
        + concatStringsSep "\n" (mapAttrsToList mkSection sections)
        + mkFields fields;
    in
    toHyprconf' initialIndent attrs;

  toKDL =
    { }:
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
    { }:
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
