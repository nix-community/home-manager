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

  # A predicate that returns true only for camelCase.
  isCamelCase =
    str:
    # This regex enforces the entire structure:
    # - Must start with one or more lowercase letters.
    # - Must be followed by one or more "humps" of an uppercase letter
    #   and then subsequent lowercase letters/numbers.
    builtins.match "^[a-z]+([A-Z][a-z0-9]*)+$" str != null;

  # Returns true for strings like `PascalCase`, `Application`, `URLShortener`.
  # Must start with an uppercase letter.
  isPascalCase = str: builtins.match "^[A-Z][a-z0-9]*([A-Z][a-z0-9]*)*$" str != null;

  # Returns true for strings like `snake_case`, `a_longer_variable`, `var1`.
  # Must be all lowercase letters/numbers, with words separated by single underscores.
  isSnakeCase = str: builtins.match "^[a-z0-9]+(_[a-z0-9]+)*$" str != null;

  # Returns true for strings like `kebab-case`, `a-css-class-name`.
  # Must be all lowercase letters/numbers, with words separated by single hyphens.
  isKebabCase = str: builtins.match "^[a-z0-9]+(-[a-z0-9]+)*$" str != null;

  # Returns true for strings like `SCREAMING_SNAKE_CASE`, `SOME_CONSTANT`.
  # Must be all uppercase letters/numbers, with words separated by single underscores.
  isScreamingSnakeCase = str: builtins.match "^[A-Z0-9]+(_[A-Z0-9]+)*$" str != null;
}
