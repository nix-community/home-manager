{ lib }:

let
  isColor = v: builtins.isAttrs v && v ? r && v ? g && v ? b;

  # Each component is a 7-char right-aligned field.
  fmtComponent = f: lib.fixedWidthString 7 " " (toString (builtins.floor (f * 65535.0 + 0.5)));

  renderColor =
    c:
    let
      vals = fmtComponent c.r + fmtComponent c.g + fmtComponent c.b + fmtComponent (c.a or 1.0);
    in
    "(color \"R'G'B'A float\" 16 \"${vals}\" 0)";

  renderScalar =
    v:
    if builtins.isBool v then
      if v then "yes" else "no"
    else if builtins.isInt v || builtins.isFloat v then
      toString v
    else if
      builtins.match "[a-zA-Z][a-zA-Z0-9._-]*" v != null || builtins.match "[0-9]+[bBkKmMgG]?" v != null
    then
      v
    else
      "\"${lib.escape [ "\"" "\\" ] v}\"";

  renderLeaf = v: if isColor v then renderColor v else renderScalar v;

  renderCompound =
    v: "\n" + lib.concatMapStringsSep "\n" (k: "    (${k} ${renderLeaf v.${k}})") (lib.attrNames v);

  renderValue =
    v:
    if isColor v then
      "\n    ${renderColor v}"
    else if builtins.isAttrs v then
      renderCompound v
    else
      renderScalar v;

in
{
  toGimprc =
    settings:
    lib.concatMapStringsSep "\n" (name: "(${name} ${renderValue settings.${name}})") (
      lib.attrNames settings
    )
    + "\n";
}
