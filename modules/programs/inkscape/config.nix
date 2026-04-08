{
  config,
  lib,
  pkgs,
  ...
}:

let
  xml = import ./xml.nix { inherit lib; };
  xmlFormat = pkgs.formats.xml { };

  cfg = config.programs.inkscape;

  # Resolve a user-supplied value (either a store path or inline text) to a store path :0
  toSource =
    name: content:
    if builtins.isPath content || lib.isStorePath content then content else pkgs.writeText name content;

  # Build xdg.configFile entries from an attrsOf (either path lines) option.
  mkConfigFiles =
    subdir: items:
    lib.mapAttrs' (
      name: content: lib.nameValuePair "inkscape/${subdir}/${name}" { source = toSource name content; }
    ) items;

in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = lib.mkMerge [
      (lib.mkIf (cfg.settings != { }) {
        "inkscape/preferences.xml".text = xml.preferencesToXml cfg.settings;
      })

      (lib.mkIf (cfg.keymap != { } || cfg.keymapSet != null) {
        "inkscape/keys/default.xml".source = xmlFormat.generate "default.xml" (
          if cfg.keymap != { } then
            cfg.keymap
          else
            {
              keys = {
                "@name" = "default";
                "xi:include" = {
                  "@href" = "${cfg.package}/share/inkscape/keys/${cfg.keymapSet}.xml";
                  "@xmlns:xi" = "http://www.w3.org/2001/XInclude";
                };
              };
            }
        );
      })

      (mkConfigFiles "templates" cfg.templates)
      (mkConfigFiles "symbols" cfg.symbols)
      (mkConfigFiles "palettes" cfg.colorPalettes)
      (mkConfigFiles "paint" cfg.patterns)
      (mkConfigFiles "filters" cfg.filters)
      (mkConfigFiles "extensions" cfg.extensions)

      (lib.listToAttrs (
        map (
          font: lib.nameValuePair "inkscape/fonts/${baseNameOf (toString font)}" { source = font; }
        ) cfg.fonts
      ))

      (lib.mapAttrs' (
        name: text: lib.nameValuePair "inkscape/fontscollections/${name}" { inherit text; }
      ) cfg.fontCollections)
    ];
  };
}
