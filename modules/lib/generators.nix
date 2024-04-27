{ lib }:

{

  toKDL = { }:
    let
      inherit (lib) concatStringsSep;
      inherit (builtins) typeOf replaceStrings elem;

      # KDL Spec Summary
      # Document -> Node[]
      # Node -> {[Type] NodeName [Args] [Properties] [Children]}
      # Type -> Ident
      # NodeName -> Ident
      # Args -> Value[] # Note: ordered
      # Properties -> map[Ident]Value # Note: Unordered
      # Children -> Node[] # Note: ordered
      # Value -> String | Number | Bool | Null

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

      # Node Attrset Conversion
      # AttrsOf Anything -> String
      attrsToKDLNode = attrs:
        let
          optType = lib.optionalString (attrs ? "type") attrs.type;

          name = attrs.name;

          optArgsString = lib.optionalString (attrs ? "args")
            (lib.pipe attrs.args [
              (a: if typeOf a == "list" then a else [ a ])
              (map literalValueToString)
              (lib.concatStringsSep " ")
            ]);

          optPropsString = lib.optionalString (attrs ? "props")
            (lib.pipe attrs.props [
              (lib.mapAttrsToList
                (name: value: "${name}=${literalValueToString value}"))
              (lib.concatStringsSep " ")
            ]);

          optChildren = lib.optionalString (attrs ? "children")
            (lib.pipe attrs.children [
              (a: if typeOf a == "list" then a else [ a ])
              (map attrsToKDLNode)
              (s:
                lib.optionalString (builtins.length s > 0) ''
                  {
                  ${indentStrings s}
                  }'')
            ]);

        in lib.concatStringsSep " " (lib.filter (s: s != "") [
          optType
          name
          optArgsString
          optPropsString
          optChildren
        ]);

    in nodes: ''
      ${concatStringsSep "\n" (map attrsToKDLNode nodes)}
    '';

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
