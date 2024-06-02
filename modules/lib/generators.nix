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
      genInner =
        key: value: builtins.toString key + indentSpace + lib.hm.generators.toSwayConf innerArgs value;
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
        ;

      initialIndent = concatStrings (replicate indentLevel "  ");

      toHyprconf' =
        indent: attrs:
        let
          sections = filterAttrs (n: v: isAttrs v || (isList v && all isAttrs v)) attrs;

          mkSection =
            n: attrs:
            if lib.isList attrs then
              (concatMapStringsSep "\n" (a: mkSection n a) attrs)
            else
              ''
                ${indent}${n} {
                ${toHyprconf' "  ${indent}" attrs}${indent}}
              '';

          mkFields = generators.toKeyValue {
            listsAsDuplicateKeys = true;
            inherit indent;
          };

          allFields = filterAttrs (n: v: !(isAttrs v || (isList v && all isAttrs v))) attrs;

          isImportantField =
            n: _: foldl (acc: prev: if hasPrefix prev n then true else acc) false importantPrefixes;

          importantFields = filterAttrs isImportantField allFields;

          fields = builtins.removeAttrs allFields (mapAttrsToList (n: _: n) importantFields);
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
