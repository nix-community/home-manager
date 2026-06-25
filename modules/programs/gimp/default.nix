{
  config,
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

in
{
  meta.maintainers = [ lib.maintainers.philocalyst ];

  imports = [ ./config.nix ];

  options.programs.gimp = {
    enable = mkEnableOption "GIMP image editor";

    package = mkPackageOption pkgs "gimp" { nullable = true; };

    configVersion = mkOption {
      type = types.str;
      default =
        if config.programs.gimp.package != null then
          lib.versions.majorMinor config.programs.gimp.package.version
        else
          "3.0";
      defaultText = literalExpression "lib.versions.majorMinor config.programs.gimp.package.version";
      example = "2.10";
      description = ''
        Config directory version suffix.
        Determines {file}`$XDG_CONFIG_HOME/GIMP/<configVersion>/`.
        Automatically derived from the package version when
        {option}`programs.gimp.package` is set (`"2.10"` for GIMP 2.x,
        `"3.0"` for GIMP 3.x).
      '';
    };

    settings = mkOption {
      type =
        let
          scalar = types.oneOf [
            types.bool
            types.int
            types.float
            types.str
          ];
          # leafAttrs covers both {r,g,b,a} colour attrsets and flat compound sub-values.
          leafAttrs = types.attrsOf scalar;
          leaf = types.either scalar leafAttrs;

          # compound covers settings whose sub-values may be scalars or colours.
          compound = types.attrsOf leaf;
        in
        types.attrsOf (types.either leaf compound);
      default = { };
      example = literalExpression ''
        {
          # Scalar settings
          single-window-mode = true;
          undo-levels        = 5;
          tile-cache-size    = "4g";
          num-processors     = 4;
          interpolation-type = "cubic";
          default-brush      = "2. Hardness 050";
          show-tooltips      = false;
          theme              = "Default";
          icon-size          = "auto";

          default-image = {
            width           = 1920;
            height          = 1080;
            unit            = "pixels";
            xresolution     = 300.0;
            yresolution     = 300.0;
            resolution-unit = "inches";
            color-mode      = "rgb";
            precision       = "linear-unsigned-8";
            fill-type       = "background";
            comment         = "Created with GIMP";
          };

          color-management = {
            mode                        = "display";
            display-profile-from-gdk    = true;
            display-rendering-intent    = "perceptual";
            simulation-gamut-check      = false;
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
        - Strings matching an identifier pattern (e.g. `cubic`, `linear-light`) → unquoted symbol
        - Memory sizes (e.g. `"4g"`, `"512m"`) → unquoted
        - All other strings → `"double-quoted"`

        Attrset values produce compound settings with indented children, covering
        `default-image`, `color-management`, and similar blocks.

        Colour values: an attrset with `r`, `g`, `b` keys (normalised floats
        `0.0`–`1.0`) is rendered as a GIMP colour S-expression
        `(color "R'G'B'A float" 16 "…" 0)`. The `a` (alpha) key is optional
        and defaults to `1.0` (opaque). Colours may appear as top-level values
        (`quick-mask-color`) or as sub-values inside compound settings
        (`default-grid` `fgcolor`/`bgcolor`).
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = ''
        (default-image
            (width 1920)
            (height 1080)
            (unit pixels)
            (xresolution 300.000000)
            (yresolution 300.000000)
            (resolution-unit inches)
            (color-mode rgb)
            (precision linear-unsigned-8)
            (fill-type background)
            (comment "Created with GIMP"))

        (color-management
            (mode display)
            (display-profile-from-gdk yes)
            (display-rendering-intent perceptual)
            (simulation-gamut-check no))
      '';
      description = ''
        Raw gimprc lines appended after {option}`programs.gimp.settings`.
        Use this for compound settings with nested S-expressions.
      '';
    };

    brushes = mkOption {
      type = types.attrsOf (types.either types.path types.lines);
      default = { };
      example = literalExpression ''
        { "my-brush.gbr" = ./my-brush.gbr; }
      '';
      description = ''
        Brush files installed to {file}`$XDG_CONFIG_HOME/GIMP/<version>/brushes/`.
        Supported formats: `.gbr` (raster), `.gih` (image hose), `.vbr` (parametric),
        `.myb` (MyPaint, GIMP 2.10+).
      '';
    };

    gradients = mkOption {
      type = types.attrsOf (types.either types.path types.lines);
      default = { };
      example = literalExpression ''
        { "sunset.ggr" = ./sunset.ggr; }
      '';
      description = ''
        Gradient files (`.ggr`) installed to
        {file}`$XDG_CONFIG_HOME/GIMP/<version>/gradients/`.
      '';
    };

    patterns = mkOption {
      type = types.attrsOf (types.either types.path types.lines);
      default = { };
      example = literalExpression ''
        { "concrete.pat" = ./concrete.pat; }
      '';
      description = ''
        Pattern files installed to {file}`$XDG_CONFIG_HOME/GIMP/<version>/patterns/`.
        Supported formats: `.pat` and common image formats (`.png`, `.jpg`).
      '';
    };

    palettes = mkOption {
      type = types.attrsOf (types.either types.path types.lines);
      default = { };
      example = literalExpression ''
        {
          "brand.gpl" = '''
            GIMP Palette
            Name: Brand Colors
            #
            255   0   0	Red
              0 128   0	Green
              0   0 255	Blue
          ''';
        }
      '';
      description = ''
        Palette files (`.gpl`) installed to
        {file}`$XDG_CONFIG_HOME/GIMP/<version>/palettes/`.
      '';
    };

    fonts = mkOption {
      type = types.listOf types.path;
      default = [ ];
      example = literalExpression ''
        [ "''${pkgs.inter}/share/fonts/truetype/inter/Inter-Regular.ttf" ]
      '';
      description = ''
        Font files installed to {file}`$XDG_CONFIG_HOME/GIMP/<version>/fonts/`.
        Available inside GIMP without a system-wide font install.
      '';
    };

    scripts = mkOption {
      type = types.attrsOf (types.either types.path types.lines);
      default = { };
      example = literalExpression ''
        {
          "auto-save.scm" = '''
            (define (auto-save image)
              (gimp-image-clean-all image)
              (gimp-displays-flush))
            (gimp-extension-enable "auto-save")
          ''';
        }
      '';
      description = ''
        Script-Fu (`.scm`) scripts installed to
        {file}`$XDG_CONFIG_HOME/GIMP/<version>/scripts/`.
        Appear in **Filters → Script-Fu** and are available for batch processing.
      '';
    };

    plugins = mkOption {
      type = types.attrsOf types.path;
      default = { };
      example = literalExpression ''
        { "my-plugin/my-plugin" = "''${pkgs.my-gimp-plugin}/lib/gimp/2.0/plug-ins/my-plugin"; }
      '';
      description = ''
        Plug-in files installed to {file}`$XDG_CONFIG_HOME/GIMP/<version>/plug-ins/`.
        Values must be paths to executables; inline text is not supported.
        Group multi-file plug-ins under a subdirectory
        (e.g. `"my-plugin/my-plugin"`).
      '';
    };

    dynamics = mkOption {
      type = types.attrsOf (types.either types.path types.lines);
      default = { };
      example = literalExpression ''
        { "pressure-opacity.dynamics" = ./pressure-opacity.dynamics; }
      '';
      description = ''
        Paint dynamics files (`.dynamics`) installed to
        {file}`$XDG_CONFIG_HOME/GIMP/<version>/dynamics/`.
      '';
    };

    toolPresets = mkOption {
      type = types.attrsOf (types.either types.path types.lines);
      default = { };
      example = literalExpression ''
        { "soft-eraser.gtp" = ./soft-eraser.gtp; }
      '';
      description = ''
        Tool preset files (`.gtp`) installed to
        {file}`$XDG_CONFIG_HOME/GIMP/<version>/tool-presets/`.
        Appear in the **Tool Presets** dialog.
      '';
    };

    mypaintBrushes = mkOption {
      type = types.attrsOf (types.either types.path types.lines);
      default = { };
      example = literalExpression ''
        { "ink-dry.myb" = ./ink-dry.myb; }
      '';
      description = ''
        MyPaint brush files (`.myb`) installed to
        {file}`$XDG_CONFIG_HOME/GIMP/<version>/mypaint-brushes/`.
        Available in GIMP 2.10+ and 3.x.
      '';
    };

    environ = mkOption {
      type = types.attrsOf types.lines;
      default = { };
      example = literalExpression ''
        { "python-path.env" = "PYTHONPATH=/my/site-packages"; }
      '';
      description = ''
        Environment files installed to
        {file}`$XDG_CONFIG_HOME/GIMP/<version>/environ/`.
        Each file sets `KEY=VALUE` environment variables injected into
        plug-in processes at launch.
      '';
    };

    keyboardShortcuts = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            modifiers = mkOption {
              type = types.listOf (
                types.enum [
                  "primary"
                  "shift"
                  "alt"
                  "super"
                ]
              );
              default = [ ];
              description = ''
                Modifier keys. `primary` is Ctrl on Linux/Windows and Cmd on macOS.
              '';
            };
            key = mkOption {
              type = types.str;
              default = "";
              description = ''
                Key name: a letter such as `"c"`, or a named key such as
                `"Return"`, `"F1"`, or `"Delete"`.
                Leave empty with no modifiers to unassign the shortcut.
              '';
            };
          };
        }
      );
      default = { };
      example = literalExpression ''
        {
          "edit-copy"  = { modifiers = [ "primary" ];            key = "c"; };
          "edit-paste" = { modifiers = [ "primary" ];            key = "v"; };
          "edit-undo"  = { modifiers = [ "primary" "shift" ];    key = "z"; };
          "file-quit"  = { modifiers = [ "primary" ];            key = "q"; };
          "select-all" = { };
        }
      '';
      description = ''
        Keyboard shortcuts written to {file}`$XDG_CONFIG_HOME/GIMP/<version>/shortcutsrc`.

        Attribute names are GIMP 3.0 action names such as `"edit-copy"`, `"file-new"`,
        or `"select-all"`. Open **Edit → Keyboard Shortcuts** in GIMP to browse
        available action names.

        An empty attrset `{ }` writes `(action "name")`, unassigning that shortcut.

        Note: GIMP rewrites `shortcutsrc` on exit, overwriting this file.
      '';
    };

    controllers = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            enabled = mkOption {
              type = types.bool;
              default = true;
              description = "Whether this controller is active.";
            };
            events = mkOption {
              type = types.listOf (
                types.submodule {
                  options = {
                    stroke = mkOption {
                      type = types.str;
                      description = ''
                        Input event identifier, e.g. `"key-cursor-up"` or `"mse-scroll-down"`.
                      '';
                    };
                    action = mkOption {
                      type = types.str;
                      description = ''
                        GIMP action path, e.g. `"tools/gimp-paintbrush"`.
                      '';
                    };
                  };
                }
              );
              default = [ ];
              description = "Stroke → action bindings for this controller.";
            };
          };
        }
      );
      default = { };
      example = literalExpression ''
        {
          GimpControllerKeyboard = {
            enabled = true;
            events = [
              { stroke = "key-cursor-up";   action = "tools/gimp-paintbrush"; }
              { stroke = "key-cursor-down"; action = "context/gimp-context-opacity-decrease"; }
            ];
          };
          GimpControllerMouse = {
            enabled = false;
            events = [];
          };
        }
      '';
      description = ''
        Input device controllers written to
        {file}`$XDG_CONFIG_HOME/GIMP/<version>/controllerrc`.

        Attribute names are GIMP controller type names: `GimpControllerKeyboard`,
        `GimpControllerMouse`, `GimpControllerWheel`, or `GimpInputDeviceCoords`.

        Note: GIMP rewrites `controllerrc` on exit, overwriting this file.
      '';
    };

    extraControllerrc = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Raw lines appended after the generated `controllerrc`.
        Use for controller types not expressible via {option}`programs.gimp.controllers`.
      '';
    };

    themes = mkOption {
      type = types.attrsOf types.path;
      default = { };
      example = literalExpression ''
        { "MyDark" = ./my-dark-theme; }
      '';
      description = ''
        GTK theme directories installed to
        {file}`$XDG_CONFIG_HOME/GIMP/<version>/themes/<name>/`.
        Each value must be a path to a directory containing a GTK theme
        (at minimum a `gtk-3.0/gtk.css`).
        Select the theme in GIMP under **Edit → Preferences → Interface → Theme**.
      '';
    };

    icons = mkOption {
      type = types.attrsOf types.path;
      default = { };
      example = literalExpression ''
        { "Papirus" = "''${pkgs.papirus-icon-theme}/share/icons/Papirus"; }
      '';
      description = ''
        Icon theme directories installed to
        {file}`$XDG_CONFIG_HOME/GIMP/<version>/icons/<name>/`.
        Each value must be a path to an icon theme directory containing
        an `index.theme` file.
        Select the icon theme in GIMP under **Edit → Preferences → Interface → Icon Theme**.
      '';
    };
  };
}
