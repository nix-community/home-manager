{ lib }:

{
  toHyprconf = { attrs, indentLevel ? 0, importantPrefixes ? [ "$" ], }:
    let
      inherit (lib)
        all concatMapStringsSep concatStrings concatStringsSep filterAttrs foldl
        generators hasPrefix isAttrs isList mapAttrsToList replicate;

      initialIndent = concatStrings (replicate indentLevel "  ");

      toHyprconf' = indent: attrs:
        let
          sections =
            filterAttrs (n: v: isAttrs v || (isList v && all isAttrs v)) attrs;

          mkSection = n: attrs:
            if lib.isList attrs then
              (concatMapStringsSep "\n" (a: mkSection n a) attrs)
            else ''
              ${indent}${n} {
              ${toHyprconf' "  ${indent}" attrs}${indent}}
            '';

          mkFields = generators.toKeyValue {
            listsAsDuplicateKeys = true;
            inherit indent;
          };

          allFields =
            filterAttrs (n: v: !(isAttrs v || (isList v && all isAttrs v)))
            attrs;

          isImportantField = n: _:
            foldl (acc: prev: if hasPrefix prev n then true else acc) false
            importantPrefixes;

          importantFields = filterAttrs isImportantField allFields;

          fields = builtins.removeAttrs allFields
            (mapAttrsToList (n: _: n) importantFields);
        in mkFields importantFields
        + concatStringsSep "\n" (mapAttrsToList mkSection sections)
        + mkFields fields;
    in toHyprconf' initialIndent attrs;

  toKDL = { }:
    let
      inherit (lib) concatStringsSep splitString mapAttrsToList any;
      inherit (builtins) typeOf replaceStrings elem;

      # ListOf String -> String
      indentStrings = let
        # Although the input of this function is a list of strings,
        # the strings themselves *will* contain newlines, so you need
        # to normalize the list by joining and resplitting them.
        unlines = lib.splitString "\n";
        lines = lib.concatStringsSep "\n";
        indentAll = lines: concatStringsSep "\n" (map (x: "	" + x) lines);
      in stringsWithNewlines: indentAll (unlines (lines stringsWithNewlines));

      # String -> String
      sanitizeString = replaceStrings [ "\n" ''"'' ] [ "\\n" ''\"'' ];

      # OneOf [Int Float String Bool Null] -> String
      literalValueToString = element:
        lib.throwIfNot
        (elem (typeOf element) [ "int" "float" "string" "bool" "null" ])
        "Cannot convert value of type ${typeOf element} to KDL literal."
        (if typeOf element == "null" then
          "null"
        else if element == false then
          "false"
        else if element == true then
          "true"
        else if typeOf element == "string" then
          ''"${sanitizeString element}"''
        else
          toString element);

      # Attrset Conversion
      # String -> AttrsOf Anything -> String
      convertAttrsToKDL = name: attrs:
        let
          optArgsString = lib.optionalString (attrs ? "_args")
            (lib.pipe attrs._args [
              (map literalValueToString)
              (lib.concatStringsSep " ")
              (s: s + " ")
            ]);

          optPropsString = lib.optionalString (attrs ? "_props")
            (lib.pipe attrs._props [
              (lib.mapAttrsToList
                (name: value: "${name}=${literalValueToString value}"))
              (lib.concatStringsSep " ")
              (s: s + " ")
            ]);

          children =
            lib.filterAttrs (name: _: !(elem name [ "_args" "_props" ])) attrs;
        in ''
          ${name} ${optArgsString}${optPropsString}{
          ${indentStrings (mapAttrsToList convertAttributeToKDL children)}
          }'';

      # List Conversion
      # String -> ListOf (OneOf [Int Float String Bool Null])  -> String
      convertListOfFlatAttrsToKDL = name: list:
        let flatElements = map literalValueToString list;
        in "${name} ${concatStringsSep " " flatElements}";

      # String -> ListOf Anything -> String
      convertListOfNonFlatAttrsToKDL = name: list: ''
        ${name} {
        ${indentStrings (map (x: convertAttributeToKDL "-" x) list)}
        }'';

      # String -> ListOf Anything  -> String
      convertListToKDL = name: list:
        let elementsAreFlat = !any (el: elem (typeOf el) [ "list" "set" ]) list;
        in if elementsAreFlat then
          convertListOfFlatAttrsToKDL name list
        else
          convertListOfNonFlatAttrsToKDL name list;

      # Combined Conversion
      # String -> Anything  -> String
      convertAttributeToKDL = name: value:
        let vType = typeOf value;
        in if elem vType [ "int" "float" "bool" "null" "string" ] then
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
    in attrs: ''
      ${concatStringsSep "\n" (mapAttrsToList convertAttributeToKDL attrs)}
    '';

  # https://github.com/ron-rs/ron/blob/master/docs/grammar.md
  toRON = { }:
    let
      inherit (lib)
        filterAttrs concatStrings concatStringsSep mapAttrsToList boolToString
        optionalString;
      inherit (lib.strings) floatToString;
      inherit (builtins) any hasAttr isAttrs toString typeOf;

      tab = "    ";

      serialize = indentLevel: input:
        let
          indent = lib.strings.replicate indentLevel tab;
          indentNested = indent + tab;
          serializeNested = v: serialize (indentLevel + 1) v;

          name = input._name or "";
          suffix = input._suffix or "";
          value = if isAttrs input && any (attr: hasAttr attr input) [
            "_name"
            "_suffix"
            "_type"
            "_value"
          ] then
            input._value or null
          else
            input;

          delimiter = {
            apostrophe = {
              open = "'";
              close = "'";
            };
            brace = {
              open = "{";
              close = "}";
            };
            bracket = {
              open = "[";
              close = "]";
            };
            none = {
              open = "";
              close = "";
            };
            parenthesis = {
              open = "(";
              close = ")";
            };
            quote = {
              open = ''"'';
              close = ''"'';
            };
          }.${
              {
                char = "apostrophe";
                enum = if isNull value then "none" else "parenthesis";
                list = if name == "" then "bracket" else "parenthesis";
                map = "brace";
                set = if name == "" then "brace" else "parenthesis";
                string = "quote";
                struct = "parenthesis";
                tuple = "parenthesis";
              }.${input._type or (typeOf value)} or "none"
            };

          serializationRules = {
            int = toString;
            float = floatToString;
            path = toString;
            bool = boolToString;
            string = toString;
            null = _: "";
            set = set:
              lib.pipe set [
                (mapAttrsToList
                  (k: v: "${indentNested}${k}: ${serializeNested v}"))
                (concatStringsSep ("," + "\n"))
                (v:
                  optionalString (v != "") "\n" + v
                  + optionalString (v != "") ("\n" + indent))
              ];
            list = list:
              lib.pipe list [
                (map (v: "${indentNested}${serializeNested v}"))
                (concatStringsSep ("," + "\n"))
                (v:
                  optionalString (v != "") "\n" + v
                  + optionalString (v != "") ("\n" + indent))
              ];
          };
        in name + delimiter.open + (serializationRules.${typeOf value} value)
        + delimiter.close + suffix;
    in serialize 0;

  toSCFG = { }:
    let
      inherit (lib) concatStringsSep mapAttrsToList any;
      inherit (builtins) typeOf replaceStrings elem;

      # ListOf String -> String
      indentStrings = let
        # Although the input of this function is a list of strings,
        # the strings themselves *will* contain newlines, so you need
        # to normalize the list by joining and resplitting them.
        unlines = lib.splitString "\n";
        lines = lib.concatStringsSep "\n";
        indentAll = lines: concatStringsSep "\n" (map (x: "	" + x) lines);
      in stringsWithNewlines: indentAll (unlines (lines stringsWithNewlines));

      # String -> Bool
      specialChars = s:
        any (char: elem char (reserved ++ [ " " "'" "{" "}" ]))
        (lib.stringToCharacters s);

      # String -> String
      sanitizeString =
        replaceStrings reserved [ ''\"'' "\\\\" "\\r" "\\n" "\\t" ];

      reserved = [ ''"'' "\\" "\r" "\n" "	" ];

      # OneOf [Int Float String Bool] -> String
      literalValueToString = element:
        lib.throwIfNot (elem (typeOf element) [ "int" "float" "string" "bool" ])
        "Cannot convert value of type ${typeOf element} to SCFG literal."
        (if element == false then
          "false"
        else if element == true then
          "true"
        else if typeOf element == "string" then
          if element == "" || specialChars element then
            ''"${sanitizeString element}"''
          else
            element
        else
          toString element);

      # Bool -> ListOf (OneOf [Int Float String Bool]) -> String
      toOptParamsString = cond: list:
        lib.optionalString (cond) (lib.pipe list [
          (map literalValueToString)
          (concatStringsSep " ")
          (s: " " + s)
        ]);

      # Attrset Conversion
      # String -> AttrsOf Anything -> String
      convertAttrsToSCFG = name: attrs:
        let
          optParamsString = toOptParamsString (attrs ? "_params") attrs._params;
        in ''
          ${name}${optParamsString} {
          ${indentStrings (convertToAttrsSCFG' attrs)}
          }'';

      # Attrset Conversion
      # AttrsOf Anything -> ListOf String
      convertToAttrsSCFG' = attrs:
        mapAttrsToList convertAttributeToSCFG
        (lib.filterAttrs (name: val: !isNull val && name != "_params") attrs);

      # List Conversion
      # String -> ListOf (OneOf [Int Float String Bool]) -> String
      convertListOfFlatAttrsToSCFG = name: list:
        let optParamsString = toOptParamsString (list != [ ]) list;
        in "${name}${optParamsString}";

      # Combined Conversion
      # String -> Anything  -> String
      convertAttributeToSCFG = name: value:
        lib.throwIf (name == "") "Directive must not be empty"
        (let vType = typeOf value;
        in if elem vType [ "int" "float" "bool" "string" ] then
          "${name} ${literalValueToString value}"
        else if vType == "set" then
          convertAttrsToSCFG name value
        else if vType == "list" then
          convertListOfFlatAttrsToSCFG name value
        else
          throw ''
            Cannot convert type `(${typeOf value})` to SCFG:
              ${name} = ${toString value}
          '');
    in attrs:
    lib.optionalString (attrs != { }) ''
      ${concatStringsSep "\n" (convertToAttrsSCFG' attrs)}
    '';
}
