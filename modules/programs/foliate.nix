{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    mkIf
    types
    mapAttrs'
    nameValuePair
    ;

  cfg = config.programs.foliate;
  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = [ lib.maintainers.awwpotato ];

  options.programs.foliate = {
    enable = mkEnableOption "Foliate";
    package = mkPackageOption pkgs "foliate" { nullable = true; };
    settings = mkOption {
      type = with types; attrsOf (either lib.hm.types.gvariant (attrsOf lib.hm.types.gvariant));
      default = { };
      description = ''
        Added to `config.dconf.settings` under `com/github/johnfactotum/Foliate`,
        the scheme is defined at
        <https://github.com/johnfactotum/foliate/blob/gtk4/data/com.github.johnfactotum.Foliate.gschema.xml>
      '';
      example = lib.literalExpression ''
        {
          myTheme = {
            color-scheme = 0;
            library = {
              view-mode = "grid";
              show-covers = true;
            };
            "viewer/view" = {
              theme = "myTheme.json";
            };
            "viewer/font" = {
              monospace = "Maple Mono";
              default-size = 12;
            };
          };
        }
      '';
    };
    themes = mkOption {
      type = types.attrsOf (
        types.oneOf [
          jsonFormat.type
          types.str
          types.path
        ]
      );
      description = ''
        Each theme is written to
        {file}`$XDG_CONFIG_HOME/com.github.johnfactotum.Foliate/themes/NAME.json`.
        See <https://github.com/johnfactotum/foliate/blob/gtk4/src/themes.js>
        for implementation of themes in Foliate.
      '';
      default = { };
      example = lib.literalExpression ''
        {
          label = "My Theme";
          light = {
            fg = "#89b4fa";
            bg = "#1e1e2e";
            link = "#89b4fa";
          };
          dark = { };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.foliate" pkgs lib.platforms.linux)
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    dconf.settings = mapAttrs' (
      name: value:
      if builtins.isAttrs value then
        nameValuePair "com/github/johnfactotum/Foliate/${name}" value
      else
        nameValuePair "com/github/johnfactotum/Foliate" { ${name} = value; }
    ) cfg.settings;

    xdg.configFile = mapAttrs' (
      name: value:
      nameValuePair "com.github.johnfactotum.Foliate/themes/${name}.json" {
        source =
          if lib.isString value then
            pkgs.writeText "foliate-theme-${name}" value
          else if builtins.isPath value || lib.isStorePath value then
            value
          else
            jsonFormat.generate "foliate-theme-${name}" value;
      }
    ) cfg.themes;
  };
}
