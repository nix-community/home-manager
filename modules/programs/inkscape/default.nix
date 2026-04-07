{
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    literalExpression
    mkEnableOption
    mkOption
    mkPackageOption
    types
    ;

  xmlFormat = pkgs.formats.xml { };

in
{
  meta.maintainers = with lib.maintainers; [ philocalyst ];

  imports = [ ./config.nix ];

  options.programs.inkscape = {
    enable = mkEnableOption "Inkscape vector graphics editor";

    package = mkPackageOption pkgs "inkscape" { };

    settings = mkOption {
      type = types.attrsOf xmlFormat.type;
      default = { };
      example = literalExpression ''
        {
          ui = {
            "@theme"   = "Adwaita";
            "@iconset" = "multicolor";
          };
          "tools.nodes" = {
            "@show_handles" = 1;
            "@show_outline" = 0;
          };
          behavior = {
            "@some_flag" = 0;
            transforms = { "@transform" = 1; };
          };
          snap = { "@global" = 1; };
        }
      '';
      description = ''
        Preferences written to
        {file}`$XDG_CONFIG_HOME/inkscape/preferences.xml`.

        Each top-level attribute becomes a `<group id="…">` element under the
        `<group id="preferences">` root.  Within a group:

        - Keys prefixed with `@` (e.g. `"@theme"`) become XML attributes.
        - Plain keys whose values are attrsets become nested `<group>` children.

        Consult your existing {file}`preferences.xml` or the
        [Inkscape wiki](https://inkscape.org/doc/) for available group IDs
        and attribute names.

        ::: {.note}
        Inkscape overwrites {file}`preferences.xml` on exit.  The file is a
        read-only store symlink when managed by Home Manager; Inkscape will
        log a warning but continue working, and settings are restored on
        every `home-manager switch`.
        :::
      '';
    };

    keymap = mkOption {
      type = types.nullOr (
        types.enum [
          "inkscape"
          "inkscape-13"
          "illustrator"
          "xara"
          "corel"
          "default"
        ]
      );
      default = null;
      example = "illustrator";
      description = ''
        Predefined keyboard shortcut set bundled with Inkscape to activate.
        Writes {file}`$XDG_CONFIG_HOME/inkscape/keys/default.xml` with an
        XInclude reference to the chosen keymap.

        Ignored when {option}`programs.inkscape.keymapXml` is set.
      '';
    };

    keymapXml = mkOption {
      type = types.nullOr types.lines;
      default = null;
      example = ''
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <keys name="default">
          <bind key="F2" action="node-tool" display="true"/>
          <bind key="F1" action="select-tool" display="true"/>
        </keys>
      '';
      description = ''
        Custom keyboard shortcut XML written verbatim to
        {file}`$XDG_CONFIG_HOME/inkscape/keys/default.xml`.
        Takes precedence over {option}`programs.inkscape.keymap`.
      '';
    };

    templates = mkOption {
      type = types.attrsOf (types.either types.path types.lines);
      default = { };
      example = literalExpression ''
        { "my-a4.svg" = ./templates/my-a4.svg; }
      '';
      description = ''
        SVG templates installed to
        {file}`$XDG_CONFIG_HOME/inkscape/templates/`.
        Appear in **File → New from Template**.
        Each attribute name is the filename; the value is either a path or
        inline text.
      '';
    };

    symbols = mkOption {
      type = types.attrsOf (types.either types.path types.lines);
      default = { };
      example = literalExpression ''
        { "my-icons.svg" = ./my-icons.svg; }
      '';
      description = ''
        SVG files with symbol definitions installed to
        {file}`$XDG_CONFIG_HOME/inkscape/symbols/`.
        Appear as collections in **Object → Symbols**.
      '';
    };

    colorPalettes = mkOption {
      type = types.attrsOf (types.either types.path types.lines);
      default = { };
      example = literalExpression ''
        { "brand.gpl" = ./brand-colors.gpl; }
      '';
      description = ''
        Palette files installed to
        {file}`$XDG_CONFIG_HOME/inkscape/palettes/`.
        Supported formats: SVG swatches, GIMP Palette (`.gpl`),
        Adobe Swatch Exchange (`.ase`), Adobe Color Book (`.acb`).
        Appear in the palette bar and **Object → Swatches**.
      '';
    };

    patterns = mkOption {
      type = types.attrsOf (types.either types.path types.lines);
      default = { };
      example = literalExpression ''
        { "hatching.svg" = ./hatching-patterns.svg; }
      '';
      description = ''
        SVG files with pattern definitions installed to
        {file}`$XDG_CONFIG_HOME/inkscape/paint/`.
        Appear in the pattern dropdown in
        **Object → Fill and Stroke**.
      '';
    };

    filters = mkOption {
      type = types.attrsOf (types.either types.path types.lines);
      default = { };
      example = literalExpression ''
        { "vintage.svg" = ./vintage-filters.svg; }
      '';
      description = ''
        SVG files with filter effect definitions installed to
        {file}`$XDG_CONFIG_HOME/inkscape/filters/`.
        Appear under **Filters → Custom**.
      '';
    };

    extensions = mkOption {
      type = types.attrsOf (types.either types.path types.lines);
      default = { };
      example = literalExpression ''
        {
          "my-ext/my-ext.inx" = ./my-ext.inx;
          "my-ext/my-ext.py"  = ./my-ext.py;
        }
      '';
      description = ''
        Extension files installed to
        {file}`$XDG_CONFIG_HOME/inkscape/extensions/`.
        Prefix the attribute name with a subdirectory to group multi-file
        extensions (e.g. `"my-ext/my-ext.inx"`).
      '';
    };

    fonts = mkOption {
      type = types.listOf types.path;
      default = [ ];
      example = literalExpression ''
        [ "''${pkgs.inter}/share/fonts/truetype/inter/Inter-Regular.ttf" ]
      '';
      description = ''
        Font files installed to
        {file}`$XDG_CONFIG_HOME/inkscape/fonts/`.
        Available inside Inkscape without a system-wide install.
      '';
    };

    fontCollections = mkOption {
      type = types.attrsOf types.lines;
      default = { };
      example = literalExpression ''
        {
          "design.txt" = '''
            Inter
            Roboto Mono
            Source Sans Pro
          ''';
        }
      '';
      description = ''
        Font collection files installed to
        {file}`$XDG_CONFIG_HOME/inkscape/fontscollections/`.
        Each attribute name is the filename; the value is a
        newline-separated list of font family names.
      '';
    };
  };
}
