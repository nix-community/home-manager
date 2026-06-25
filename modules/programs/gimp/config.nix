{
  config,
  lib,
  pkgs,
  ...
}:
let
  gimprc = import ./gimprc.nix { inherit lib; };
  shortcutsrc = import ./shortcutsrc.nix { inherit lib; };
  ctrlrc = import ./controllerrc.nix { inherit lib; };

  cfg = config.programs.gimp;
  configDir = "GIMP/${cfg.configVersion}";

  toSource =
    name: content:
    if lib.isPath content || lib.isStorePath content then content else pkgs.writeText name content;

  mkContentFiles =
    subdir: items:
    lib.concatMapAttrs (name: content: {
      "${configDir}/${subdir}/${name}" = {
        source = toSource name content;
      };
    }) items;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = lib.mkMerge [
      (lib.mkIf (cfg.settings != { } || cfg.extraConfig != "") {
        "${configDir}/gimprc".text =
          lib.optionalString (cfg.settings != { }) (gimprc.toGimprc cfg.settings) + cfg.extraConfig;
      })

      (mkContentFiles "brushes" cfg.brushes)
      (mkContentFiles "gradients" cfg.gradients)
      (mkContentFiles "patterns" cfg.patterns)
      (mkContentFiles "palettes" cfg.palettes)
      (mkContentFiles "scripts" cfg.scripts)
      (mkContentFiles "dynamics" cfg.dynamics)
      (mkContentFiles "tool-presets" cfg.toolPresets)
      (mkContentFiles "mypaint-brushes" cfg.mypaintBrushes)

      (lib.listToAttrs (
        map (
          font: lib.nameValuePair "${configDir}/fonts/${baseNameOf (toString font)}" { source = font; }
        ) cfg.fonts
      ))

      (lib.concatMapAttrs (name: content: {
        "${configDir}/plug-ins/${name}" = {
          source = content;
        };
      }) cfg.plugins)

      (lib.concatMapAttrs (name: text: {
        "${configDir}/environ/${name}" = { inherit text; };
      }) cfg.environ)

      (lib.mkIf (cfg.keyboardShortcuts != { }) {
        "${configDir}/shortcutsrc".text = shortcutsrc.toShortcutSource cfg.keyboardShortcuts;
      })

      (lib.mkIf (cfg.controllers != { } || cfg.extraControllerrc != "") {
        "${configDir}/controllerrc".text =
          lib.optionalString (cfg.controllers != { }) (ctrlrc.toControllerrc cfg.controllers)
          + cfg.extraControllerrc;
      })

      (lib.concatMapAttrs (name: src: {
        "${configDir}/themes/${name}" = {
          source = src;
        };
      }) cfg.themes)

      (lib.concatMapAttrs (name: src: {
        "${configDir}/icons/${name}" = {
          source = src;
        };
      }) cfg.icons)
    ];
  };
}
