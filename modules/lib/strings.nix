{ lib }:

let
  inherit (lib)
    genList
    length
    lowerChars
    replaceStrings
    stringToCharacters
    upperChars
    ;
in
rec {
  # Figures out a valid Nix store name for the given path.
  storeFileName =
    path:
    let
      # All characters that are considered safe. Note "-" is not
      # included to avoid "-" followed by digit being interpreted as a
      # version.
      safeChars =
        [
          "+"
          "."
          "_"
          "?"
          "="
        ]
        ++ lowerChars
        ++ upperChars
        ++ stringToCharacters "0123456789";

      empties = l: genList (x: "") (length l);

      unsafeInName = stringToCharacters (replaceStrings safeChars (empties safeChars) path);

      safeName = replaceStrings unsafeInName (empties unsafeInName) path;
    in
    "hm_" + safeName;

  /*
    Convert a string from camelCase or PascalCase to another case format using a separator
    Type: string -> string -> string
  */
  toCaseWithSeparator =
    separator: string:
    let
      splitByWords = builtins.split "([A-Z])";
      processWord = s: if lib.isString s then s else separator + lib.toLower (lib.elemAt s 0);
      words = splitByWords string;
      converted = lib.concatStrings (map processWord words);
    in
    lib.removePrefix separator converted;

  /*
    Convert a string from camelCase or PascalCase to snake_case
    Type: string -> string
  */
  toSnakeCase = toCaseWithSeparator "_";

  /*
    Convert a string from camelCase or PascalCase to kebab-case
    Type: string -> string
  */
  toKebabCase = toCaseWithSeparator "-";
}
