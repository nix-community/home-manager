{ lib }:
let
  sexp = import ./gimprc.nix { inherit lib; };

  renderToolOptions =
    class: options:
    if class == null && options == { } then
      ""
    else if class == null && options != { } then
      throw "gimp toolPresets: toolOptions requires toolOptionsClass to be specified."
    else if options == { } then
      "(tool-options \"${class}\")\n"
    else
      let
        renderPair = key: value: "    (${key} ${sexp.renderValue "    " value})";
      in
      "(tool-options \"${class}\"\n"
      + lib.concatStringsSep "\n" (lib.mapAttrsToList renderPair options)
      + ")\n";
in
{
  toToolPresetFile =
    preset:
    "# GIMP tool preset file\n\n"
    + lib.optionalString (preset.iconName != "") "(icon-name ${sexp.renderScalar preset.iconName})\n"
    + "(name ${sexp.renderScalar preset.name})\n"
    + renderToolOptions preset.toolOptionsClass preset.toolOptions
    + "(use-fg-bg ${sexp.renderBoolean preset.useFgBg})\n"
    + "(use-brush ${sexp.renderBoolean preset.useBrush})\n"
    + "(use-dynamics ${sexp.renderBoolean preset.useDynamics})\n"
    + "(use-mypaint-brush ${sexp.renderBoolean preset.useMypaintBrush})\n"
    + "(use-gradient ${sexp.renderBoolean preset.useGradient})\n"
    + "(use-pattern ${sexp.renderBoolean preset.usePattern})\n"
    + "(use-palette ${sexp.renderBoolean preset.usePalette})\n"
    + "(use-font ${sexp.renderBoolean preset.useFont})\n"
    + "\n# end of GIMP tool preset file\n";
}
