{ lib }:

let
  spaces = n: lib.fixedWidthString n " ";

  # The 'r', 'g', 'b', and 'a' attributes are retained as-is because they
  # map directly to the literal target property names within the GIMP schema.
  isColor = value: builtins.isAttrs value && value ? r && value ? g && value ? b;

  # Each color component is normalized to a 16-bit integer string, right-aligned to 7 spaces.
  formatColorComponent =
    component: spaces " " (toString (builtins.floor (component * 65535.0 + 0.5)));

  renderColor =
    color:
    let
      alpha = color.a or 1.0;
      componentValues =
        formatColorComponent color.r
        + formatColorComponent color.g
        + formatColorComponent color.b
        + formatColorComponent alpha;
    in
    "(color \"R'G'B'A float\" 16 \"${componentValues}\" 0)";

  renderScalar =
    value:
    if builtins.isBool value then
      if value then "yes" else "no"
    else if builtins.isInt value || builtins.isFloat value then
      toString value
    else if
      builtins.match "[a-zA-Z][a-zA-Z0-9._-]*" value != null
      || builtins.match "[0-9]+[bBkKmMgG]?" value != null
    then
      value
    else
      "\"${lib.escape [ "\"" "\\" ] value}\"";

  renderValue =
    indentation: value:
    if isColor value then
      renderColor value
    else if builtins.isAttrs value then
      let
        nextIndentation = indentation + spaces 4;
        renderPair =
          key: childValue: "${nextIndentation}(${key} ${renderValue nextIndentation childValue})";
        lines = lib.mapAttrsToList renderPair value;
      in
      "\n" + lib.concatStringsSep "\n" lines
    else
      renderScalar value;
in
{
  toGimpConfiguration =
    settings:
    let
      renderTopLevel = key: value: "(${key} ${renderValue "" value})";
      lines = lib.mapAttrsToList renderTopLevel settings;
    in
    lib.concatStringsSep "\n" lines + "\n";
}
