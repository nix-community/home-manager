{ lib, ... }:
let
  inherit (lib) literalExpression mkOption types;

  scalarType = types.oneOf [
    types.bool
    types.int
    types.float
    types.str
  ];

  nestedSettingsType = lib.mkOptionType {
    name = "nestedSettings";
    description = "a scalar value or an arbitrarily deeply nested attribute set of settings";
    check =
      value:
      scalarType.check value
      || (builtins.isAttrs value && lib.all nestedSettingsType.check (builtins.attrValues value));
    merge =
      location: definitions:
      let
        isAttrSet = d: builtins.isAttrs d.value;
        attrDefs = builtins.filter isAttrSet definitions;
        scalarDefs = builtins.filter (d: !isAttrSet d) definitions;
      in
      if scalarDefs != [ ] && attrDefs != [ ] then
        throw "Conflict at ${lib.showFiles location}: cannot merge a scalar value with a nested attribute set."
      else if attrDefs != [ ] then
        (types.attrsOf nestedSettingsType).merge location attrDefs
      else
        scalarType.merge location scalarDefs;
  };
in
{
  options.programs.gimp = {
    settings = mkOption {
      type = types.attrsOf nestedSettingsType;
      default = { };
      example = literalExpression ''
        {
          undo-levels        = 5;
          tile-cache-size    = { symbol = "4g"; };
          interpolation-type = { symbol = "cubic"; };
          default-brush      = "2. Hardness 050";
          show-tooltips      = false;
          default-image = {
            width  = 1920;
            height = 1080;
            unit   = { symbol = "pixels"; };
          };
          quick-mask-color = { r = 1.0; g = 0.0; b = 0.0; a = 0.5; };
          default-grid = {
            xspacing = 10.0;
            yspacing = 10.0;
            fgcolor  = { r = 0.0; g = 0.0; b = 0.0; };
            bgcolor  = { r = 1.0; g = 1.0; b = 1.0; };
          };
        }
      '';
      description = ''
        Settings written to {file}`$XDG_CONFIG_HOME/GIMP/<version>/gimprc`
        as `(key value)` S-expression lines.

        Scalar value rules:
        - Booleans → `yes` / `no`
        - Integers and floats → bare number
        - Strings → `"double-quoted"` (this is what most GIMP properties,
          including ones that look like bare words, actually expect - e.g.
          `theme`, or the `brush`/`gradient`/`tool` keys GIMP itself writes
          into `.gtp` tool presets, are all quoted strings)
        - `{ symbol = "..."; }` → unquoted symbol/atom, for the minority of
          properties that need one instead (GIMP's `GParamEnum` properties
          such as `cursor-mode` or `unit`, and bare-suffix tokens such as
          `tile-cache-size = { symbol = "4g"; }`). Getting this wrong in
          either direction is a fatal gimprc parse error that makes GIMP
          discard the whole file and fall back to defaults, so when in doubt
          leave a value as a plain string first.

        Colour values: an attrset with `r`, `g`, `b` keys (normalised floats
        `0.0`–`1.0`) renders as a GIMP colour S-expression. The `a` key is
        optional and defaults to `1.0` (opaque). `r`/`g`/`b`/`a` must be
        numbers in `0.0`–`1.0`; e.g. 0-255 values (as used by
        {option}`programs.gimp.palettes` `.gpl` entries) are out of range
        here and will fail to evaluate rather than silently rendering an
        out-of-gamut colour.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = ''
        (default-image
            (width 1920)
            (height 1080)
            (unit pixels))
      '';
      description = ''
        Raw gimprc lines appended after {option}`programs.gimp.settings`.
      '';
    };
  };
}
