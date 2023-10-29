{ lib }:

{
  toKDL = {}:
    let
      inherit (lib) mapAttrsToList;
      inherit (builtins) typeOf replaceStrings elem;
      inherit (lib.lists) flatten;

      indentListOfStrings = list: map (x: "	" + x) list;

      # String -> String
      sanitizeName = replaceStrings [ "'" ] [ ''"'' ];
      sanitizeValue = replaceStrings [ "\n" ''"'' ] [ "\\n" ''\"'' ];

      isLiteral = element:
        (elem (typeOf element) [ "int" "float" "bool" "null" "string" ]);

      # OneOf [Int Float String Bool Null] -> String
      convertLiteralValueToString = isName: element:
        lib.throwIfNot (isLiteral element)
          "Cannot convert value of type ${typeOf element} to KDL literal."
          (if typeOf element == "null" then
            "null"
          else if element == false then
            "false"
          else if element == true then
            "true"
          else if typeOf element == "string" then
            if isName then
              sanitizeName element
            else
              ''"'' + sanitizeValue element + ''"''
          else
            toString element);

      convertListElement = elem:
        if builtins.isAttrs elem then
          convertSetToKDL elem
        else
          builtins.trace elem (convertLiteralValueToString true elem);

      # flatten list first since hierarchical lists are equivalent to flattened lists
      # in KDL
      convertListToKDL = list: flatten (map convertListElement (flatten list));

      convertSetElement = name: value:
        let
          emptyRet = [ (sanitizeName name) ];
          prefix = [ (sanitizeName name + " {") ];
          suffix = [ "}" ];
        in
        if builtins.isList value then
          if value == [ ] then
            emptyRet
          else
            prefix ++ indentListOfStrings (convertListToKDL value) ++ suffix
        else if builtins.isAttrs value then
          if value == { } then
            emptyRet
          else
            prefix ++ indentListOfStrings (convertSetToKDL value) ++ suffix
        else
          sanitizeName name + " " + (convertLiteralValueToString false value);

      convertSetToKDL = set: flatten (mapAttrsToList convertSetElement set);
    in
    attrs: lib.concatStringsSep "\n" (flatten (convertSetToKDL attrs));
}
