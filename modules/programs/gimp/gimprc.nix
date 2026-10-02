{ lib }:

let
  # Generates a string of empty spaces for indentation
  spaces = length: lib.fixedWidthString length " " "";

  # The 'r', 'g', 'b', and 'a' attributes map directly to the literal target
  # property names within the GIMP schema, so they are retained as-is.
  isColor = value: builtins.isAttrs value && value ? r && value ? g && value ? b;

  # Identifies explicit bare symbols (e.g. { symbol = "cursor-mode"; })
  isSymbol = value: builtins.isAttrs value && builtins.attrNames value == [ "symbol" ];

  # Validates and extracts a bare gimprc symbol token
  renderSymbol =
    { symbol }:
    if builtins.isString symbol && builtins.match "[a-zA-Z0-9_][a-zA-Z0-9._-]*" symbol != null then
      symbol
    else
      throw ''
        gimp settings: { symbol = ${builtins.toJSON symbol}; } is not a valid bare gimprc symbol (must be a non-empty string of letters, digits, '.', '_' or '-', starting with a letter/digit/underscore).
      '';

  # GIMP's gimprc scanner (gimp_scanner_parse_double) only accepts numeric
  # G_TOKEN_FLOAT/G_TOKEN_INT tokens for colour components
  isNormalisedColorComponent = v: (builtins.isInt v || builtins.isFloat v) && v >= 0.0 && v <= 1.0;

  renderColor =
    {
      r,
      g,
      b,
      a ? 1.0,
      ...
    }:
    if
      isNormalisedColorComponent r
      && isNormalisedColorComponent g
      && isNormalisedColorComponent b
      && isNormalisedColorComponent a
    then
      "(color-rgba ${toString r} ${toString g} ${toString b} ${toString a})"
    else
      throw ''
        gimp settings: ${
          builtins.toJSON {
            inherit
              r
              g
              b
              a
              ;
          }
        } is not a valid GIMP colour
        (r, g, b, and the optional a must all be numbers normalised to 0.0-1.0).
      '';

  # Renders booleans to GIMP's yes/no format
  renderBoolean = value: if value then "yes" else "no";

  # Renders basic scalar types.
  # Plain strings are ALWAYS quoted (GParamString) since we cannot infer schema.
  # Use { symbol = "..."; } for unquoted identifiers (GParamEnum).
  renderScalar =
    value:
    if builtins.isBool value then
      renderBoolean value
    else if builtins.isInt value || builtins.isFloat value then
      toString value
    else
      "\"${lib.escape [ "\"" "\\" ] value}\"";

  # Core formatting abstraction for key-value pairings used in both top-level and nested attrs
  renderExpression =
    indentation: key: value:
    "${indentation}(${key} ${renderValue indentation value})";

  # Recursively resolves any GIMP configuration value
  renderValue =
    indentation: value:
    if isColor value then
      renderColor value
    else if isSymbol value then
      renderSymbol value
    else if builtins.isList value then
      lib.concatMapStringsSep " " (v: renderValue indentation v) value
    else if builtins.isAttrs value then
      "\n"
      + lib.concatStringsSep "\n" (lib.mapAttrsToList (renderExpression (indentation + spaces 4)) value)
    else
      renderScalar value;

  # Converts a Nix attribute set into a full GIMP configuration block
  toGimpConfiguration =
    settings: lib.concatStringsSep "\n" (lib.mapAttrsToList (renderExpression "") settings) + "\n";

  # Wraps settings in the standard GIMP file header and footer strings
  toSExpressionFile =
    fileType: settings:
    "# GIMP ${fileType} file\n\n${toGimpConfiguration settings}\n# end of GIMP ${fileType} file\n";

  gimpValueType = lib.mkOptionType {
    name = "gimpValue";
    description = "a GIMP s-expression value (boolean, number, string, symbol, color, list, or nested attribute set of GIMP values)";
    check =
      v:
      builtins.isBool v
      || builtins.isInt v
      || builtins.isFloat v
      || builtins.isString v
      || isSymbol v
      || isColor v
      || (builtins.isList v && lib.all gimpValueType.check v)
      || (builtins.isAttrs v && lib.all gimpValueType.check (builtins.attrValues v));
    merge = location: definitions: lib.mergeOneOption location definitions;
  };
in
{
  inherit
    gimpValueType
    isColor
    isSymbol
    renderBoolean
    renderColor
    renderScalar
    renderSymbol
    renderValue
    spaces
    toGimpConfiguration
    toSExpressionFile
    ;
}
