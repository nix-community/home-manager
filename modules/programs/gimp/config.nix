{
  config,
  lib,
  pkgs,
  ...
}:

let
  gimpConfigurationModule = import ./gimprc.nix { inherit lib; };
  shortcutConfigurationModule = import ./shortcutsrc.nix { inherit lib; };
  controllerConfigurationModule = import ./controllerrc.nix { inherit lib; };
  gtpModule = import ./gtp.nix { inherit lib; };
  gplModule = import ./gpl.nix { inherit lib; };
  gdynModule = import ./gdyn.nix { inherit lib; };
  mybModule = import ./myb.nix { inherit lib; };
  vbrModule = import ./vbr.nix { inherit lib; };

  configuration = config.programs.gimp;
  configurationDirectory = "GIMP/${configuration.configVersion}";
  useXdgDirectories = !pkgs.stdenv.hostPlatform.isDarwin || config.home.preferXdgDirectories;

  # Ensures raw strings become store paths, while existing paths pass through unmodified.
  toSource =
    name: content:
    if lib.isPath content || lib.isStorePath content then content else pkgs.writeText name content;

  # Like toSource, but automatically applies a rendering function to structured attrsets.
  toRenderedSource =
    renderFunction: name: value:
    if lib.isPath value || lib.isStorePath value then
      value
    else
      pkgs.writeText name (if builtins.isString value then value else renderFunction value);

  # Helper to generate Home Manager file mappings for unrendered paths/strings
  renderContent =
    basePath: configurationSet:
    lib.mapAttrs' (
      name: value: lib.nameValuePair "${basePath}/${name}" { source = toSource name value; }
    ) configurationSet;

  # Helper to generate Home Manager file mappings for resources requiring structural rendering
  renderResource =
    basePath: renderFunction: configurationSet:
    lib.mapAttrs' (
      name: value:
      lib.nameValuePair "${basePath}/${name}" { source = toRenderedSource renderFunction name value; }
    ) configurationSet;

  majorVersion = lib.versions.major configuration.configVersion;

  fontsMap =
    if builtins.isAttrs configuration.fonts then
      configuration.fonts
    else
      let
        fontBasenames = map (
          f: builtins.unsafeDiscardStringContext (baseNameOf (toString f))
        ) configuration.fonts;
        uniqueBasenames = lib.unique fontBasenames;
      in
      assert lib.assertMsg (lib.length fontBasenames == lib.length uniqueBasenames)
        "programs.gimp.fonts: list contains duplicate font filenames (${lib.concatStringsSep ", " fontBasenames})";
      lib.listToAttrs (
        map (
          font: lib.nameValuePair (builtins.unsafeDiscardStringContext (baseNameOf (toString font))) font
        ) configuration.fonts
      );

  allConfigurationFiles =
    # Standard unrendered resources (strings or paths)
    lib.concatMapAttrs (directory: items: renderContent "${configurationDirectory}/${directory}" items)
      {
        inherit (configuration)
          brushes
          gradients
          patterns
          scripts
          themes
          icons
          ;
        "plug-ins" = configuration.plugins;
      }

    # Rendered structured resources
    //
      renderResource "${configurationDirectory}/palettes" gplModule.toPaletteFile
        configuration.palettes
    //
      renderResource "${configurationDirectory}/dynamics" gdynModule.toDynamicsFile
        configuration.dynamics
    //
      renderResource "${configurationDirectory}/tool-presets" gtpModule.toToolPresetFile
        configuration.toolPresets
    //
      renderResource "${configurationDirectory}/brushes" vbrModule.toVbrFile
        configuration.parametricBrushes
    // renderContent "${configurationDirectory}/fonts" fontsMap

    # Environment files (direct text assignment instead of source path)
    // lib.mapAttrs' (
      name: text: lib.nameValuePair "${configurationDirectory}/environ/${name}" { inherit text; }
    ) configuration.environ

    # Base configuration files (gimprc, shortcutsrc, controllerrc)
    // lib.optionalAttrs (configuration.settings != { } || configuration.extraConfig != "") {
      "${configurationDirectory}/gimprc".text =
        lib.optionalString (configuration.settings != { }) (
          gimpConfigurationModule.toGimpConfiguration configuration.settings
        )
        + configuration.extraConfig;
    }
    // lib.optionalAttrs (configuration.keyboardShortcuts != { }) {
      "${configurationDirectory}/shortcutsrc".text =
        shortcutConfigurationModule.toShortcutSource configuration.keyboardShortcuts;
    }
    // lib.optionalAttrs (configuration.controllers != { } || configuration.extraControllerrc != "") {
      "${configurationDirectory}/controllerrc".text =
        lib.optionalString (configuration.controllers != { }) (
          controllerConfigurationModule.toControllerConfiguration configuration.controllers
        )
        + configuration.extraControllerrc;
    };

  # NOT under configurationDirectory (GIMP/<version>/...): MyPaint brushes
  # bypass XDG preferences and GIMP versioning. GIMP's default setting for
  # `mypaint-brush-path-writable` hard-defaults to ~/.mypaint/brushes.
  mypaintFiles = renderResource ".mypaint/brushes" mybModule.toBrushFile configuration.mypaintBrushes;
in
{
  config = lib.mkIf configuration.enable {
    home.packages = lib.mkIf (configuration.package != null) [ configuration.package ];

    home.sessionVariables = lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && useXdgDirectories) {
      "GIMP${majorVersion}_DIRECTORY" = "${config.xdg.configHome}/${configurationDirectory}";
    };

    xdg.configFile = lib.mkIf useXdgDirectories allConfigurationFiles;

    home.file =
      lib.optionalAttrs (!useXdgDirectories) (
        lib.mapAttrs' (
          name: value: lib.nameValuePair "Library/Application Support/${name}" value
        ) allConfigurationFiles
      )
      // mypaintFiles;
  };
}
