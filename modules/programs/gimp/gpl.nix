{ lib }:
let
  padInt = n: lib.fixedWidthString 3 " " (toString n);
  renderColor =
    color:
    "${padInt color.r} ${padInt color.g} ${padInt color.b}"
    + lib.optionalString (color.name != "") "\t${color.name}";
in
{
  toPaletteFile =
    palette:
    "GIMP Palette\n"
    + "Name: ${palette.name}\n"
    + lib.optionalString (palette.columns != 0) "Columns: ${toString palette.columns}\n"
    + "#\n"
    + lib.concatMapStrings (c: renderColor c + "\n") palette.colors;
}
