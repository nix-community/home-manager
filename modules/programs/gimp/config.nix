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

  configuration = config.programs.gimp;
  configurationDirectory = "GIMP/${configuration.configVersion}";
  useXdgDirectories = !pkgs.stdenv.hostPlatform.isDarwin || config.home.preferXdgDirectories;

  toSource =
    name: content:
    if lib.isPath content || lib.isStorePath content then content else pkgs.writeText name content;

  contentFiles =
    lib.concatMapAttrs
      (
        directory: items:
        lib.concatMapAttrs (name: content: {
          "${configurationDirectory}/${directory}/${name}".source = toSource name content;
        }) items
      )
      {
        "brushes" = configuration.brushes;
        "gradients" = configuration.gradients;
        "patterns" = configuration.patterns;
        "palettes" = configuration.palettes;
        "scripts" = configuration.scripts;
        "dynamics" = configuration.dynamics;
        "tool-presets" = configuration.toolPresets;
        "mypaint-brushes" = configuration.mypaintBrushes;
      };

  sourceFiles =
    lib.concatMapAttrs
      (
        directory: items:
        lib.concatMapAttrs (name: source: {
          "${configurationDirectory}/${directory}/${name}".source = source;
        }) items
      )
      {
        "plug-ins" = configuration.plugins;
        "themes" = configuration.themes;
        "icons" = configuration.icons;
      };

  fontFiles =
    let
      getFontName = font: builtins.unsafeDiscardStringContext (baseNameOf (toString font));
      buildFontAttribute =
        font: lib.nameValuePair "${configurationDirectory}/fonts/${getFontName font}" { source = font; };
    in
    lib.listToAttrs (map buildFontAttribute configuration.fonts);

  environmentFiles = lib.concatMapAttrs (name: text: {
    "${configurationDirectory}/environ/${name}" = { inherit text; };
  }) configuration.environ;

  baseFiles =
    (lib.optionalAttrs (configuration.settings != { } || configuration.extraConfig != "") {
      "${configurationDirectory}/gimprc".text =
        lib.optionalString (configuration.settings != { }) (
          gimpConfigurationModule.toGimpConfiguration configuration.settings
        )
        + configuration.extraConfig;
    })
    // (lib.optionalAttrs (configuration.keyboardShortcuts != { }) {
      "${configurationDirectory}/shortcutsrc".text =
        shortcutConfigurationModule.toShortcutSource configuration.keyboardShortcuts;
    })
    // (lib.optionalAttrs (configuration.controllers != { } || configuration.extraControllerrc != "") {
      "${configurationDirectory}/controllerrc".text =
        lib.optionalString (configuration.controllers != { }) (
          controllerConfigurationModule.toControllerConfiguration configuration.controllers
        )
        + configuration.extraControllerrc;
    });

  allConfigurationFiles = baseFiles // contentFiles // sourceFiles // fontFiles // environmentFiles;
in
{
  config = lib.mkIf configuration.enable {
    home.packages = lib.mkIf (configuration.package != null) [ configuration.package ];

    xdg.configFile = lib.mkIf useXdgDirectories allConfigurationFiles;

    home.file = lib.mkIf (!useXdgDirectories) (
      lib.mapAttrs' (
        name: value: lib.nameValuePair "Library/Application Support/${name}" value
      ) allConfigurationFiles
    );
  };
}
