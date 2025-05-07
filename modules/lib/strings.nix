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
{
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
       Convert a string from camelCase to snake_case
    Type: string -> string
  */
  toSnakeCase =
    let
      splitByWords = builtins.split "([A-Z])";
      processWord = s: if lib.isString s then s else "_" + lib.toLower (lib.elemAt s 0);
    in
    string:
    let
      words = splitByWords string;
    in
    lib.concatStrings (map processWord words);

  /*
       Convert a string from camelCase to kebab-case
    Type: string -> string
  */
  toKebabCase =
    let
      splitByWords = builtins.split "([A-Z])";
      processWord = s: if lib.isString s then s else "-" + lib.toLower (lib.elemAt s 0);
    in
    string:
    let
      words = splitByWords string;
    in
    lib.concatStrings (map processWord words);
}
